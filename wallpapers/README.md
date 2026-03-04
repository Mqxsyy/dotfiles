Put all wallpapers in this folder, can contain directories and subdirectories

Sources:
https://drive.google.com/drive/folders/1GwBykGeMJ3pF_mcbdA9TX9RgzC_3dyzQ
https://endfield.gryphline.com/special/over-the-frontier
https://arknights.global/fankit

Get all ULRs from network
```js
copy(performance.getEntriesByType("resource")
    .map(e => e.name)
    .join("\n"))
```

Batch download from links
```sh
aria2c -i urls.txt -d ~/Downloads

```
