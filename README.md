# Swift Docker Actions

![swift >= 4.0](https://img.shields.io/badge/swift-%3E%3D4.0-brightgreen.svg)
![macOS](https://img.shields.io/badge/os-macOS-green.svg?style=flat)
![Linux](https://img.shields.io/badge/os-linux-green.svg?style=flat)
[![Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg?style=flat)](LICENSE.md)

CLI Application used to instantiate docker containers and execute swift commands

## Requirements

* Xcode 9+ (If working within Xcode)
* Swift 4.0+

## Usage

### Docker Hub List

CLI Application used to list the tags of docker images

**Parameters**:
> **-tf, --tagFilter**: Filter tag names by string
>
> **-te, --tagExclude**: Exclude tags names by string
>
> **-tfx, --tagFilterX**: Filter tag names by regular expression
>
> **-tex, --tagExcludeX**: Exclude tag names by regular expression
>
>  
> **-cf, --cachefolder**: The location to cache the list of docker image tags
>
> **-cd, --cacheDuration**: The duration used to load from cache before going back to the server (Duration can be in seconds (s), minutes (m), hours (h), days (d), and weeks (w).  Eg 60s, 1m, 3h, 5d, 4w)
>
> **-ic, --ignoreCache**: Ignore the cache and get image tags from server. Error will be return on failure
>
> **-uco, --useCacheOnly**: Only use cache to get image tags.  Error will be returned if no cache is available
>
> **-ucof, --useCacheOnFailure**: Indicator to use cache if failed to communicate with server even if cache has expired
>
>   
> **--similarTo**: Get tags similar to (tag as next argument). returns tags that have the same digest
>
> **-lcr, --listCachedRepos**: Returns a list of the cached images lists

```bash
docker-hub-list [PARAMETERS] {docker image: default is swift}

# List Swift Docker Tags
docker-hub-list
docker-hub-list swift

# List DSwift Docker Tags
docker-hub-list theangrydarling/dswift

# Filter version only Swift Docker Tags
docker-hub-list --tagFilterX "^[0-9](\.[0-9](\.[0-9])?)?$"
```

### Swift Docker Action

CLI Application used to execute an action within a Swift container (build, test, run, execute)

**Parameters**:

> **-sro, --swiftRepoOrder**: A ';' separated list of repo:{container cli app} to try and use as the swift image / swift app (Optional.  Default: swift)
>
> **--buildDir**: The location where the .build dir is located. (Optional)
>
> **Docker Specific Parameters**:
>
> **-t, --tag**: The swift tag of the image to use
>
> **--env**: Set environment variables.  Docker Format: NAME:VALUE
>
> **--volume**: Setup a volume map.  Docker Format: {REAL_PATH}:{VIRTUAL_PATH} or {REAL_PATH}:{VIRTUAL_PATH}:{OPTIONS}
>
> **--mount**: Attach a filesystem mount to the container.  Docker Format: 'type=XXX,source=XXX,target=XXX'

**Output Replacement Parameters**:

> **-or, --outputReplacement**: Replace text within the output
>
> **-orx, --outputReplacementX**: Replace text within the output using regular expression

**Other Parameters**:

> **--dockerPath**: The path to the Docker CLI Executable (Optional, default: /usr/local/bin/docker)

```bash
swift-docker [build|test|run|execute] [PARAMETERS] {any arguments to pass to build sub command}

# Build A Swift Project
swift-docker build --tag 4.0

# Build A Swift Project using DSwift with failover to Swift if DSwift is not available
swift-docker build --swiftRepoOrder theangrydarling/dswift;swift --tag 4.0 

# Test A Swift Project
swift-docker test --tag 4.0

# Execute Other Swift Command (package init)
swift-docker execute --tag 4.0 package init --type library

# Clean package
swift-docker execute --tag 4.0 package clean
```

#### Action Specific Applications

Same parameters as Swift Docker Action without the action parameter

- swift-docker-build - Execute swift build ...
- swift-docker-test - Execute swift test ...
- swift-docker-run - Execute swift run
- swift-docker-execute - Execute a custom swift command like '***swift package***'

```bash
# Build Project
swift-docker-build --tag 4.0

# Test Project
swift-docker-test --tag 4.0

# Other (package init)
swift-docker-execute --tag 4.0 package init --type library
```

### Swift Docker Join

Creates a Swift Docker container and joins it to allow the user to execute any CLI commands from within the container

**Parameters**:

> **-sro, --swiftRepoOrder**: A ';' separated list of repo:{container cli app} to try and use as the swift image / swift app (Optional.  Default: swift)
>
> **--buildDir**: The location where the .build dir is located. (Optional)

**Docker Specific Parameters**:

> **-t, --tag**: The swift tag of the image to use
>
> **--env**: Set environment variables.  Docker Format: NAME:VALUE
>
> **--volume**: Setup a volume map.  Docker Format: {REAL_PATH}:{VIRTUAL_PATH} or {REAL_PATH}:{VIRTUAL_PATH}:{OPTIONS}
>
> **--mount**: Attach a filesystem mount to the container.  Docker Format: 'type=XXX,source=XXX,target=XXX'

**Other Parameters**:

> **--dockerPath**: The path to the Docker CLI Executable (Optional, default: /usr/local/bin/docker)

```bash
swift-docker-join
```

### Swift Docker Range Action (Currently only supported on macOS)

CLI Application used to execute the same action on a range of Swift containers with different tags (build, test)

**Parameters**:

> **-sro, --swiftRepoOrder**: A ';' separated list of repo:{container cli app} to try and use as the swift image / swift app (Optional.  Default: swift)
>
> **--buildDir**: The location where the .build dir is located. (Optional)

**Docker Specific Parameters**:

> **--from**: The swift tag to start the rage at (Optional)
>
> **--to**: The swift tag to end before (Optional)
>
> **--through**: Through tag.  The last tag before stopping (Optional)
>
> **--env**: Set environment variables.  Docker Format: NAME:VALUE
>
> **--volume**: Setup a volume map.  Docker Format: {REAL_PATH}:{VIRTUAL_PATH} or {REAL_PATH}:{VIRTUAL_PATH}:{OPTIONS}
>
> **--mount**: Attach a filesystem mount to the container.  Docker Format: 'type=XXX,source=XXX,target=XXX'

**Docker Hub List Parameters**:

> **-tf, --tagFilter**: Filter tag names by string
>
> **-te, --tagExclude**: Exclude tags names by string
>
> **-tfx, --tagFilterX**: Filter tag names by regular expression
>
> **-tex, --tagExcludeX**: Exclude tag names by regular expression
>  
> **-cf, --cachefolder**: The location to cache the list of docker image tags
>
> **-cd, --cacheDuration**: The duration used to load from cache before going back to the server (Duration can be in seconds (s), minutes (m), hours (h), days (d), and weeks (w).  Eg 60s, 1m, 3h, 5d, 4w)
>
> **-ic, --ignoreCache**: Ignore the cache and get image tags from server. Error will be return on failure
>
> **-uco, --useCacheOnly**: Only use cache to get image tags.  Error will be returned if no cache is available
>
> **-ucof, --useCacheOnFailure**: Indicator to use cache if failed to communicate with server even if cache has expired
>   
> **--similarTo**: Get tags similar to (tag as next argument). returns tags that have the same digest

**Output Replacement Parameters**:

> **-or, --outputReplacement**: Replace text within the output
>
> **-orx, --outputReplacementX**: Replace text within the output using regular expression

**Other Parameters**:

> **--dockerPath**: The path to the Docker CLI Executable (Optional, default: /usr/local/bin/docker)

```bash
swift-docker-range [build|test|run] [PARAMETERS]

# Build Project
swift-docker-range build --from 4.0 --to 4.1 --tagFilterX "^[0-9](\.[0-9](\.[0-9])?)?$"

# Test Project
swift-docker-range test --from 4.0 --to 4.1 --tagFilterX "^[0-9](\.[0-9](\.[0-9])?)?$"

```

#### Action Specific Applications

Same parameters as Swift Docker Range Action without the action parameter

- swift-docker-build-range - Execute swift build for a range of tags
- swift-docker-test-range - Execute swift test for a range of tags
- swift-docker-run-range - Execute swift run for a range of tags

```bash
swift-docker-range [build|test|run] [PARAMETERS]

# Build Project
swift-docker-build-range --from 4.0 --to 4.1 --tagFilterX "^[0-9](\.[0-9](\.[0-9])?)?$"

# Test Project
swift-docker-test-range --from 4.0 --to 4.1 --tagFilterX "^[0-9](\.[0-9](\.[0-9])?)?$"

```


## Dependencies

* **[Swift Patches](https://github.com/TheAngryDarling/SwiftPatches)** - A collection of classes, methods, and properties to fill in the gaps on older versions of swift so witing code for multiple versions of Swift is a little easier.
* **[RegEx](https://github.com/TheAngryDarling/SwiftRegEx)** - Provides a Swift wrapper around the NSRegularExpression class that handles switching between NSRange and Range
* **[CLICapture](https://github.com/TheAngryDarling/SwiftCLICapture)** - Class used for capturing STD Out and STD Err of CLI processes
* **[WebRequest](https://github.com/TheAngryDarling/SwiftWebRequest)** - Simple classes for creating single, multiple, and repeated web requests Each class provides event handlers for start, resume, suspend, cancel, complete Each class supports Notification events for start, resume, suspend, cancel, complete
* **[SwiftUnitTestingHelper](https://github.com/TheAngryDarling/SwiftUnitTestingHelper)** - Provides an extended XCTestCase (XCExtenedTestCase) that gives access to helper methods for printing and accessing the filesystem relative to the project. 


## Author

* **Tyler Anger** - *Initial work*  - [TheAngryDarling](https://github.com/TheAngryDarling)

## License

*Copyright 2022 Tyler Anger*

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

[HERE](LICENSE.md) or [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

## Acknowledgments

The OSSignal object is based on work done by Alejandro Martínez here https://github.com/alexito4/Trap