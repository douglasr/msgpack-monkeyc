# MessagePack for MonkeyC (Garmin Connect IQ)

(c)2024 Douglas Robertson (GitHub: [douglasr](https://github.com/douglasr); Garmin Connect: dbrobert)

[MessagePack](https://msgpack.org/) is an efficient binary serialization format. It lets you exchange data among multiple languages like JSON but it's faster and smaller. For example, small integers (like flags or error code) are encoded into a single byte, and typical short strings only require an extra byte in addition to the strings themselves.

If you ever wished to use JSON for convenience (storing an image with metadata) but could not for technical reasons (binary data, size, speed...), MessagePack is a perfect replacement.

## License
This Connect IQ barrel is licensed under the "MIT License", which essentially means that while the original author retains the copyright to the original code, you are free to do whatever you'd like with this code (or any derivative of it). See the LICENSE.txt file for complete details.

## Using the Barrel
This project cannot be used on it's own; it is designed to be included in existing projects.

### Include the Barrel
Download the barrel file (and associated debug.xml) and include it in your project. See [Shareable Libraries](https://developer.garmin.com/connect-iq/core-topics/shareable-libraries/) on the Connect IQ Developer site for more details.

## Serializing objects
Use ```MessagePack.Serialize.pack```:
```
MessagePack.Serialize.pack(obj);
```

## Deserializing objects
Use ```MessagePack.Deserialize.unpack```:
```
MessagePack.Deserialize.unpack(obj);
```

## Limitations
- does not support float or double
- does not currently support extended (8-bit) ASCII characters (or Unicode for that matter) within strings
- because of device memory constraints within the Connect IQ platform, it's not likely that these will be implemented:
    - support for numbers greater than 9,223,372,036,854,775,807 (largest value for Monkey C; should probably be handled on the unpack though)
    - support for arrays bigger than 65535 elements
    - support maps (Dictionary) with more than 65535 keys
    - support for symbols (since values for symbols may change across builds)

## Contributing
Please see the CONTRIBUTING.md file for details on how contribute.

### Contributors
* [Douglas Robertson](https://github.com/douglasr)
