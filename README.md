# Usage

[Install and set up Tor](http://martincik.com/?p=402).

```
# Download the code.
git clone git@github.com:botanicus/carfolio-scrapper.git

# Fetch dependencies.
# This assumes you have bundler installed.
# If not, run gem install bundler.
cd carfolio-scrapper
bundle

# Run the scrapper.
bundle exec ./scrapper.rb
```

After you run the scrapper, you should find a new directory called `specs` with bunch of `csv` files.

# Notes

Memory consumption is high, but currently there doesn't seem to be any memory leak (at least when using the cached pages). When processing the whole data set, the memory consumption climb to 268 MB and stays there.
