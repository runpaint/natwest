# natwest

## Overview

This is a rudimentary API for [Natwest Online banking](https://nwolb.com/).

It consists of a command-line application (`nw`) that displays account
information, balance, and recent transactions.

## Usage

    $ nw
    > Please enter your customer number:
    > Please enter your PIN:
    > Please enter your password:

    12345678 (12-34-56) balance: £100,753.73; available: £100,000
    
    Recent Transactions:
    15 Jan 2010: -£40.00
      Cash Withdrawal (LLOYDS BANK 15JAN)
    18 Jan 2010: -£20.00
      Cash Withdrawal (LLOYDS BANK 17JAN)
    19 Jan 2010: -£45.00
      OnLine Transaction (CALL REF.NO. 1234 LOANSHARK FP 19/01/10 10)
    19 Jan 2010: -£49.99
      Debit Card Transaction (1234 18JAN10 EXAMPLE.COM 0800 123 4567 GB)
    20 Jan 2010: +£2,000.00
      Automated Credit
    20 Jan 2010: +£38.83
      Automated Credit

## Purpose

The login procedure for [nwolb.com](https://nwolb.com/) is pure security
theatre. It requires:

* Spoofing your useragent unless using I.E or Chrome.  Entering your customer
* number, then clicking "Log in".  Determining three specific digits of your
* PIN, then entering them in individual form
fields.
* Determining three specific characters of your password, then entering them in
* individual form
fields.
* Clicking "Next".  Confirming your last login details then clicking "Next".

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

**Warning**: `~/.natwest.yaml` should be `chmod 600`.

## Bugs

This utility relies on screen-scraping multiple pages of horrendous HTML.
Further, it has only been tested with one account. Feel free to report errors,
preferably with the HTML, appropriately sanitised, on which it fails.
