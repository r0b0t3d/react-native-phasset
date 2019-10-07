import { NativeModules } from 'react-native';

const { Phasset } = NativeModules;

function requestImage() {
    return Phasset.requestImage()
}

export default Phasset;
