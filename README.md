# react-native-phasset

## Getting started

`$ yarn react-native-phasset`

## Usage
```javascript
import Phasset from 'react-native-phasset';


const photoId = ""; // iOS: localIdenfifier, Android: filePath

const item = await PHAsset.requestImage({
	id: photoId,
	...options,
});
```
