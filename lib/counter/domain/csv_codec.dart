/// Reversible escaping for free-text fields written into the line-based,
/// comma-separated backup format.
///
/// The backup CSV is parsed by splitting each line on `,` and reading fields
/// positionally, so any field that could hold a comma or a line break (a
/// description or a category name) must be encoded so it never contains one.
/// The scheme is a minimal percent-encoding: `%` itself is escaped first so
/// the transform is losslessly reversible.
///
/// Older backups predate this codec and simply contain no `%NN` sequences, so
/// [csvDecodeField] leaves their text untouched.
String csvEncodeField(String value) => value
    .replaceAll('%', '%25')
    .replaceAll(',', '%2C')
    .replaceAll('\r', '%0D')
    .replaceAll('\n', '%0A');

/// Inverse of [csvEncodeField]. `%25` is decoded last so an escaped literal
/// like `%2C` is not mistaken for an encoded comma.
String csvDecodeField(String value) => value
    .replaceAll('%0A', '\n')
    .replaceAll('%0D', '\r')
    .replaceAll('%2C', ',')
    .replaceAll('%25', '%');
