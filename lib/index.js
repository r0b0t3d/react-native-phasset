"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
//@ts-ignore
const react_native_1 = require("react-native");
const { Phasset } = react_native_1.NativeModules;
function requestImage(params) {
    return Phasset.requestImage(params);
}
exports.default = {
    requestImage,
};
//# sourceMappingURL=index.js.map