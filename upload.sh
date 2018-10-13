bundle exec weaver build
rm -rf build/images
aws s3 sync build/ s3://staging.astrobunny.net --exclude ".DS_Store" --exclude "*.sh"
