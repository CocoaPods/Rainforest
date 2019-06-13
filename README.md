# CocoaPods Rainforest

[![Build Status](https://img.shields.io/travis/CocoaPods/Rainforest/master.svg?style=flat)](https://travis-ci.org/CocoaPods/Rainforest)


To effectively farm CocoaPods, trees are needed (the gems), and those trees need
a special and unique habitat to flourish: the Rainforest.

This repository allows you to automate the tasks necessary to develop CocoaPods.
In detail, the following tasks can be performed from a centralised location:

- Clone all repositories containing gems.
- Centralise bootstrapping of all the repositories.
- Switch to SSH URLs.
- Set up Bundler's [Local Git Repos] feature.
- Pull of all the repositories.
- Check the status of each repository, scanning for dirty working copies or
  gems which should be released.

[Local Git Repos]: https://bundler.io/guides/git.html


## Usage

To get started, simply run:

```
$ git clone https://github.com/CocoaPods/Rainforest.git
$ cd Rainforest
$ rake bootstrap
```

To check that the setup process worked, you can run the following command:

```
$ cd Rainforest
$ CocoaPods/bin/pod --help
```

The above means that you can use the checked out version of CocoaPods for
development and that you can experiment with your changes directly. If you
would like CocoaPods to pick up the changes of the other checked out
dependencies, you can use the local git repos features of Bundler:

```
$ rake local_dependencies_set
```

Finally, to see all the available tasks, run:

```
$ rake -T
```

### Useful tasks

- `rake pull`: Pulls all the repos and updates the submodules.
- `rake cleanup`: Performs safe cleanup operations, like deleting merged
  branches.
- `rake status`: Prints the repositories with unmerged branches or a dirty.
  working copy and lists the gems with commits after the last release.
- `rake issues`: Gets the count of the open issues.

### Tasks for the Core team

- `rake clone_all`: Clones all the CocoaPods repositories.
- `rake switch_to_ssh`: If SSH is your fancy.
- `rake issues`: Prints the count of the open issues for each gem.
- `rake release[gem_dir]`: Releases the gem with the given name.
- `update_rubocop_configuration[gem_dir]`: Update the shared CocoaPods RuboCop
  configuration for the given repo or for all the repos.

### Release Configuration

See [RELEASING.md](RELEASING.md).

## Collaborate

All CocoaPods development happens on GitHub; there is a repository for
[CocoaPods](https://github.com/CocoaPods/CocoaPods) and one for the [CocoaPods
specs](https://github.com/CocoaPods/Specs). Contributing patches or Pods is
really easy and gratifying.

Follow [@CocoaPods](https://twitter.com/CocoaPods) to get up to date
information about what's going on in the CocoaPods world.

## License

This gem and CocoaPods are available under the MIT license.
