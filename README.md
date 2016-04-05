# vantiq-sdk-ios

[![CI Status](http://img.shields.io/travis/Vantiq/vantiq-sdk-ios.svg?style=flat)](https://travis-ci.org/Vantiq/vantiq-sdk-ios)
[![Version](https://img.shields.io/cocoapods/v/vantiq-sdk-ios.svg?style=flat)](http://cocoapods.org/pods/vantiq-sdk-ios)
[![License](https://img.shields.io/cocoapods/l/vantiq-sdk-ios.svg?style=flat)](http://cocoapods.org/pods/vantiq-sdk-ios)
[![Platform](https://img.shields.io/cocoapods/p/vantiq-sdk-ios.svg?style=flat)](http://cocoapods.org/pods/vantiq-sdk-ios)

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.


## Installation

vantiq-sdk-ios is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "vantiq-sdk-ios"
```

## Example App
There is an example iOS app that shows one or more uses of each API call. The app prompts for authentication to the [development Vantiq server](https://dev.vantiq.com). In order to perform all API test cases, there must be a test type and a procedure defined in the namespace associated with the authenticated user.

The type must be named _TestType_ and contain the following properties:

* intValue: an Integer
* stringValue: a String
* uniqueString: a String

Also, _uniqueString_ must be designated as a **Natural Key**.

The procedure is defined as follows:

	PROCEDURE sumTwo(val1, val2)
		var result = val1 + val2
		return {result: result}

## API Documentation

An Xcode Documentation Set (docset) is built by executing the _builddoc.sh_ shell script, which is found in the Pod directory. This shell script builds both the docset and an HTML-formatted version of the API documentation, creating the output in the Pod/help directory.

## API

[HTML-format documentation](https://rawgit.com/Vantiq/vantiq-sdk-ios/master/Pod/help/html/index.html) for the SDK methods may be found in the Pod/help/html directory.

## Author

Vantiq, Inc., info@vantiq.com

## License

vantiq-sdk-ios is available under the MIT license. See the LICENSE file for more info.
