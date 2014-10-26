# natwest

## Overview

This is a rudimentary API for [Natwest Online banking](https://nwolb.com/).

It consists of a command-line application (`nw`) that displays account
information, balance, and recent transactions.

## Usage

Get a quick summary:
    
    $ nw summary
    > Please enter your customer number:
    > Please enter your PIN:
    > Please enter your password:

    12345678 (12-34-56) balance: £100,753.73; available: £100,000
    
    Recent Transactions:
    15 Jan 2010: -£40.00
      Cash Withdrawal (LLOYDS BANK 15JAN)
    18 Jan 2010: -£20.00
      Cash Withdrawal (LLOYDS BANK 17JAN)
    ...

Get transactions for one account between 2 dates:
    
    $ nw transactions 2013-08-01 2014-10-26 123
    Transactions for account ending 123, between 2013-08-01 and 2014-10-26
    Date       Description                                                 Amount
    2014-10-21 4371 20OCT14 , NATIONAL LOTTERY , INTE , WATFORD GB             -10.00
    2014-10-20 4371 17OCT14 , KATZENJAMMERS , LONDON GB                        -10.30
    2014-10-20 MOBILE PAYMENT , FROM 07123456789                                50.00
    2014-10-17 HSBC 17OCT                                                      -30.00
    ...

Hooking into the ./lib/natwest.rb methods is very easy: the transactions method
for example returns an array of transactions, each one a hash of the date, description
and amount:
    
    [
      [ 0] {
                 :date => #<Date: 2014-10-21 ((2456952j,0s,0n),+0s,2299161j)>,
          :description => "4371 20OCT14 , NATIONAL LOTTERY , INTE , WATFORD GB",
               :amount => -10.0
      },
      [ 1] {
                 :date => #<Date: 2014-10-20 ((2456951j,0s,0n),+0s,2299161j)>,
          :description => "4371 17OCT14 , KATZENJAMMERS , LONDON GB",
               :amount => -10.3
      }
    ]


## Purpose

The login procedure for [nwolb.com](https://nwolb.com/) is pure security
theatre. It requires:

* Spoofing your useragent unless using I.E or Chrome.
* Entering your customer number, then clicking "Log in".
* Determining three specific digits of your PIN, then entering them in
individual form fields.
* Determining three specific characters of your password, then entering them
in individual form fields.
* Clicking "Next".
* Confirming your last login details then clicking "Next".

(For extra difficulty, the last "Next" button is positioned under a series of
three images: if you click on it before the images have loaded, you're likely
to click one of those instead, which loads an unrelated page).

For checking an account balance or recent activity, this is ridiculous. This
utility prompts for your credentials then displays your account details.
Optionally, one or more of these credentials (remember, there are three) can
be cached in `~/.natwest.yaml`, in which case only the remaining credentials
are prompted for.

## Credential caching

A YAML file named `~/.natwest.yaml` may contain a Hash of one or more
credentials. The keys are `Symbol`s: `:pin`, `:password`, and
`:customer_number`. Their values are `String`s or `Integer`s. For example:

    $ cat ~/.natwest.yaml 
    --- 
    :customer_number: '0123045678'
    :pin: 1234

With the above config file, `nw` will prompt only for the password. You may
store all three credentials in the config file, in which case you will not be
prompted at all. However, for security reasons, that’s probably a
bad idea.

**Note**: The PIN is unrelated to your ATM card PIN.

**Warning**: `~/.natwest.yaml` should be `chmod 600`.

## Bugs

This utility relies on screen-scraping multiple pages of horrendous HTML.
Further, it has only been tested with one online account (with one current account
and one credit card). Feel free to report errors, preferably with the HTML, 
appropriately sanitised, on which it fails.