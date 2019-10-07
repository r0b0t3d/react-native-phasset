# react-native-phasset

## Getting started

`$ npm install react-native-phasset --save`

### Mostly automatic installation

`$ react-native link react-native-phasset`

### Manual installation


#### iOS

1. In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
2. Go to `node_modules` ➜ `react-native-phasset` and add `Phasset.xcodeproj`
3. In XCode, in the project navigator, select your project. Add `libPhasset.a` to your project's `Build Phases` ➜ `Link Binary With Libraries`
4. Run your project (`Cmd+R`)<

#### Android

1. Open up `android/app/src/main/java/[...]/MainApplication.java`
  - Add `import com.reactlibrary.PhassetPackage;` to the imports at the top of the file
  - Add `new PhassetPackage()` to the list returned by the `getPackages()` method
2. Append the following lines to `android/settings.gradle`:
  	```
  	include ':react-native-phasset'
  	project(':react-native-phasset').projectDir = new File(rootProject.projectDir, 	'../node_modules/react-native-phasset/android')
  	```
3. Insert the following lines inside the dependencies block in `android/app/build.gradle`:
  	```
      compile project(':react-native-phasset')
  	```


## Usage
```javascript
import Phasset from 'react-native-phasset';

// TODO: What to do with the module?
Phasset;
```
