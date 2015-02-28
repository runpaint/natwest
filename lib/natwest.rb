# coding: utf-8
require 'mechanize'
require 'time'

require 'awesome_print'

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
      @logged_in = true
    end

    private
    def enter_customer_number
      login_form = ua.get(URL).frames.first.click.forms.first
      login_form['ctl00$mainContent$LI5TABA$DBID_edit'] = customer_number
      self.page = login_form.submit
      assert(page.title.include?('PIN and password details'),
             "Got '#{page.title}' instead of PIN/Password prompt")
    end

    def enter_pin_and_password
      expected = expected('PIN','number') + expected('Password','character')
      self.page = page.forms.first.tap do |form|
       ('A'..'F').map do |letter|
         "ctl00$mainContent$Tab1$LI6PPE#{letter}_edit"
        end.zip(expected).each {|field, value| form[field] = value}
      end.submit
      assert(page.title.include?('Account summary'),
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
      @ua = Mechanize.new

      ua.user_agent_alias = 'Windows IE 7'
      ua.verify_mode = 0
      ua.pluggable_parser.default = Mechanize::Download
    end

    def accounts
      page.parser.css('table.AccountTable > tbody > tr').each_slice(2).map do |meta, statement|
        Account.new.tap do |acc|
          acc.name = meta.at('span.AccountName').inner_text
          acc.number = meta.at('span.AccountNumber').inner_text.gsub(/[^\d]/,'')
          acc.sort_code = meta.at('span.SortCode').inner_text.gsub(/[^\d-]/,'')
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

    def transactions(start_date, end_date, account)
      # TODO check end_date >= start_date?
      start_date = Date.parse(start_date)
      end_date = Date.parse(end_date)
      
      transactions = []

      this_end_date = end_date
      this_start_date = [end_date - 364, start_date].max

      while this_start_date <= this_end_date
        self.page = page.link_with(text: 'Statements').click
        assert(page.title.include?('Statements'),
               "Got '#{page.title}' instead of Statements")
        
        form = page.form_with(action: 'StatementsLandingPageA.aspx')
        button = form.button_with(value: 'Search transactions')
        self.page = form.submit(button)
        assert(page.title.include?('Transaction search - Select account and period'),
               "Got '#{page.title}' instead of Transaction search")

        self.page = page.link_with(text: 'view transactions between two dates.').click
        assert(page.title.include?('Transaction search - Select account and dates'),
               "Got '#{page.title}' instead of Transaction search - Select account and dates")

        form = page.form_with(action: 'TransactionSearchSpecificDates.aspx')
        form.field_with(name: 'ctl00$mainContent$TS2DEA_day').value = this_start_date.day
        form.field_with(name: 'ctl00$mainContent$TS2DEA_month').value = this_start_date.month
        form.field_with(name: 'ctl00$mainContent$TS2DEA_year').value = this_start_date.year
        form.field_with(name: 'ctl00$mainContent$TS2DEB_day').value = this_end_date.day
        form.field_with(name: 'ctl00$mainContent$TS2DEB_month').value = this_end_date.month
        form.field_with(name: 'ctl00$mainContent$TS2DEB_year').value = this_end_date.year
        form.field_with(name: 'ctl00$mainContent$TS2ACCDDA').option_with(text: /(.*?)#{account}/).select
        self.page = form.click_button
        assert(page.title.include?('Transaction search details'),
               "Got '#{page.title}' instead of Transaction search details")
        
        search_form = page.form_with(action: 'TransactionSearchSpecificDates.aspx')
        search_button = search_form.button_with(value: 'Search')
        self.page = search_form.submit(search_button)
        assert(page.title.include?('Transaction search results'),
               "Got '#{page.title}' instead of Transaction search results")

        if !page.link_with(text: 'All').nil?
          self.page = page.link_with(text: 'All').click
        end

        transaction_table = page.search('table.ItemTable')

        transaction_header = transaction_table.search('th > a').map { |th| th.inner_text }

        transaction_table.search('tbody > tr').each do |tr|
          values = tr.search('td').map{ |td| td.inner_text }
          tr = Hash[transaction_header.zip values.map{|v| v == ' - ' ? '0' : v}]
          transaction = {}
          transaction[:date] = Date.parse(tr['Posting date'] || tr['Date'])
          transaction[:description] = tr['Description']
          transaction[:amount] = tr['Paid in'].gsub(/,/,'').to_f - tr['Paid out'].gsub(/,/,'').to_f
          
          transactions << transaction
        end
        this_end_date = this_start_date - 1
        this_start_date = [this_end_date - 364, start_date].max
      end
      
      #transactions.reverse!
      return transactions
      
    end

  end

  class Account
    attr_accessor :name, :number, :sort_code, :balance, :available, :transactions
  end
end
