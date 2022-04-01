# Chef Cookbooks
The Uber Client Platform Engineering repo contains a suite of chef cookbooks that we use to manage our fleet of client devices at scale.

## Dependencies
The following [Facebook cookbooks](https://github.com/facebook/IT-CPE) will more than likely be required for these cookbooks to function. Please check the `metadata.rb` files in each cookbook for a complete list of dependencies.
- cpe_launchd
- cpe_profiles
- cpe_remote
- cpe_utils

## Legacy cookbooks
Cookbooks found in the `legacy` folder are no longer actively maintained by Uber, due to us no longer using the associated tools.
