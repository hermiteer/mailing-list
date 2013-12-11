mailing-list
============

A non-commercial sample project for a simple MailChimp integrated mailing list app.  It can be customized to fit your needs by changing the background and logo.  It also has an offline mode so that the app will continue to collect email addresses, then commit them to your MailChimp account the next time it has an internet connection.

HOW TO USE
==========

- Install the required ChimpKit source files by following ./ChimpKit/README.txt
- Install the required Reachability source files by following ./Reachability/README.txt
- Set your MailChimp API key, list ID, etc in ./MailingList/MLChimpKitKeys.h

HOW TO CUSTOMIZE
================

The project comes will a complete set of placeholder images for icons, backgrounds, logos for both retina and non-retina devices.  Replace these as necessary with your own resources.  You may need to move/resize backgroundImageView and logoImageView if your images are different size than the placeholders.

IMPORTANT
=========

The MailChimp API will NOT give an error response if the API key or list ID is not set.  So, if you run the project without changing those items, your collected emails are going off into the ether.  Once you've changed them, make sure to test your app by logging into your MailChimp account via the web and watching the addresses appear in the list.  No crying if you don't test this before taking your app into wild!
