# coding: utf-8
require 'mechanize'

module Kernel
  def assert(condition, message)
    raise message unless condition
  end
end

module Natwest
  URL = 'https://nwolb.com/'
  
  module Login
    attr_reader :ua, :pin
    attr_accessor :password, :pin, :customer_number

    def logged_in?
      @logged_in ||= false
    end

    def login(credentials)
      credentials.each_pair{|name, value| send("#{name}=".to_sym, value)}
      enter_customer_number
      enter_pin_and_password
      confirm_last_login
      @logged_in = true
    end

    private
    def enter_customer_number
      login_form = ua.get(URL).frames.first.click.forms.first
      login_form['ctl00$mainContent$LI5TABA$DBID_edit'] = customer_number
      self.page = login_form.submit
      assert(page.title.include?('PIN and Password details'), 
             "Got '#{page.title}' instead of PIN/Password prompt")
    end

    def enter_pin_and_password
      expected = expected('PIN','number') + expected('Password','character')
      self.page = page.forms.first.tap do |form|
       ('A'..'F').map do |letter| 
         "ctl00$mainContent$LI6PPE#{letter}_edit"
        end.zip(expected).each {|field, value| form[field] = value}
      end.submit
      assert(page.title.include?('Last log in confirmation'), 
             "Got '#{page.title}' instead of last login confirmation")
    end

    def confirm_last_login
      self.page = page.forms.first.submit
      assert(page.title.include?('Accounts summary'), 
             "Got '#{page.title}' instead of accounts summary")
    end

    def expected(credential, type)
      page.body.
           scan(/Enter the (\d+)[a-z]{2} #{type}/).
           flatten.map{|i| i.to_i - 1}.tap do |indices|
        assert(indices.uniq.size == 3, 
               "Unexpected #{credential} characters requested")
        characters = [*send(credential.downcase.to_sym).to_s.chars]
        indices.map! {|i| characters[i]}
      end
    end
  end

  class Customer
    include Login
    NO_DETAILS = 'No further transaction details held'
    attr_accessor :page

    def initialize
      @ua = Mechanize.new {|ua| ua.user_agent_alias = 'Windows IE 7'}
    end

    def accounts
      page.parser.css('table.AccountTable > tbody > tr').each_slice(2).map do |meta, statement|
        Account.new.tap do |acc|
          acc.name = meta.at('td > span.AccountName').inner_text
          acc.number = meta.at('td > span.AccountNumber').inner_text.gsub(/[^\d]/,'')
          acc.sort_code = meta.at('td > span.SortCode').inner_text.gsub(/[^\d-]/,'')
          acc.balance = meta.css('td')[-2].inner_text
          acc.available = meta.css('td')[-1].inner_text
          acc.transactions = 
            statement.css('table.InnerAccountTable > tbody > tr').map do |tr|
            transaction = Hash[[:date, :details, :credit, :debit].
              zip((cells = tr.css('td')).map(&:inner_text))]
            unless (further = cells[1]['title']) == NO_DETAILS
              transaction[:details] += " (#{further.squeeze(' ')})"
            end
            Hash[transaction.map{|k,v| [k, v == ' - ' ? nil : v]}]
          end
        end
      end
    end
  end

  class Account 
    attr_accessor :name, :number, :sort_code, :balance, :available, :transactions
  end
end
