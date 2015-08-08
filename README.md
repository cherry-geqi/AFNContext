# AFNContext

AFNContext is a Chainable, User-Friendly, Full-Featured wrapper over [AFNetworking](https://github.com/AFNetworking/AFNetworking).

## Examples

### Simple GET request

```obj-c
AFNContext
.context(nil)
.path(@"http://example.com/thing")
.exec(^(id responseObject, NSError *error) {
    // handle response or error
});
```

### POST

```obj-c
AFNContext
.context(nil)
.method(@"POST")
.addParamster(@"foo", @"bar")
.path(@"http://example.com/things")
.exec(^(id responseObject, NSError *error) {
    // handle response or error
});
```

### Multipart with upload progress

```obj-c
AFNContext
.context(nil)
.method(@"POST")
.path(@"http://example.com/things")
.addMultipartFileData(imageData, @"image", @"image.png", @"image/png")
.uploadProgress(^(CGFloat progress) {
    NSLog(@"upload progress: %@", @(progress));
})
.exec(^(id responseObject, NSError *error) {
    // handle response or error
});
```

### Download a file with progress

```obj-c
AFNContext
.context(nil)
.path(@"http://example.com/file.zip")
.downloadProgress(^(CGFloat progress) {
    NSLog(@"upload progress: %@", @(progress));
})
.exec(^(id responseObject, NSError *error) {
    // handle response or error
});

```

<!--
## Installation

### With CocoaPods
```ruby
pod 'AFNContext', '~> 1.0.0'
```
-->

## Completion Code Snippets

As AFNContext implements dot style chaining using returned blocks, Xcode does little help in code completion. Thus there are code snippets help you out.

Copy the included code snippets to ~/Library/Developer/Xcode/UserData/CodeSnippets and enjoy! :]

## License

AFNContext is released under the MIT license.
