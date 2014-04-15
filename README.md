# CocoaPods Rainforest

To effectively farm Cocoa Pods trees are needed (the gems) and those trees need
an especial and unique habitat to flourish: the Rainforest.

This repository allows to automate the task necessary to develop on CocoaPods.
In detail the following task can be performed from a centralised location:

- Cloning of all repositories containing Gems.
- Centralised bootstrap of all the repositories.
- Switch to SSH URLs.
- Setup of Bundler [Local Git Repos] feature.
- Pulling of all the repositories.
- Checking the status of each repository to check for dirty working copies or
  gems which should be released.

[Local Git Repos]: http://bundler.io/v1.5/git.html


## Usage

To get started run:

```
$ git clone https://github.com/CocoaPods/Rainforest.git
$ cd Rainforest
$ rake bootstrap
```

To check that the setup process worked you can run the following command:

```
$ cd Rainforest
$ CocoaPods/bin/pod --help
```

The above means that you can use the checked out version of CocoaPods for
development and that you can experiment with your changes directly. If you
would like CocoaPods to use pick up the changes of the other checked out
dependencies you can use the local git repos features of Bundler:

```
$ rake set_up_local_dependencies
```

Finally, to see all the available task run:

```
$ rake -T
```

## Collaborate

All CocoaPods development happens on GitHub, there is a repository for
[CocoaPods](https://github.com/CocoaPods/CocoaPods) and one for the [CocoaPods
specs](https://github.com/CocoaPods/Specs). Contributing patches or Pods is
really easy and gratifying.

Follow [@CocoaPods](http://twitter.com/CocoaPods) to get up to date
information about what's going on in the CocoaPods world.

## License

This gem and CocoaPods are available under the MIT license.
