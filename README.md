# Usage

[Install and set up Tor](http://martincik.com/?p=402).

```
# Download the code.
git clone https://gist.github.com/024075a0046a43c683b6.git scrapper

# Fetch dependencies.
# This assumes you have bundler installed.
# If not, run gem install bundler.
cd scrapper
bundle

# Run the scrapper.
bundle exec ./scrapper.rb
```

After you run the scrapper, you should find a new directory called `specs` with bunch of `csv` files.

# Notes

- There's a memory leak.
- This happens many times in a row: [ERROR] UnexpectedHttpStatusError Unexpected HTTP status: 302 on http://webcache.googleusercontent.com/search?q=cache:http://www.carfolio.com/specifications/models/car/?car=75988. Requesting new IP & retrying.
