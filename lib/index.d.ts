export interface AssetParams {
    id: string;
    assetType?: string;
}
export interface ImageRequestParams extends AssetParams {
    maxWidth?: number;
    maxHeight?: number;
}
declare function isExists({ id, assetType }: AssetParams): any;
declare function requestImage(params: ImageRequestParams): any;
declare const _default: {
    isExists: typeof isExists;
    requestImage: typeof requestImage;
};
export default _default;
