part of excel;

Excel _newExcel(Archive archive) {
  // Lookup at file format
  var format;

  var mimetype = archive.findFile('mimetype');
  if (mimetype == null) {
    var xl = archive.findFile('xl/workbook.xml');
    if (xl != null) {
      format = _spreasheetXlsx;
    }
  }

  switch (format) {
    case _spreasheetXlsx:
      return Excel._(archive);
    default:
      throw UnsupportedError('Excel format unsupported.');
  }
}

/// Decode a excel file.
class Excel {
  bool _colorChanges, _mergeChanges;
  Archive _archive;
  Map<String, XmlNode> _sheets;
  Map<String, XmlDocument> _xmlFiles;
  Map<String, String> _xmlSheetId;
  Map<String, Map<String, int>> _cellStyleReferenced;
  Map<String, Sheet> _sheetMap;
  List<CellStyle> _cellStyleList;
  List<String> _sharedStrings, _patternFill, _mergeChangeLook;
  List<_FontStyle> _fontStyleList;
  List<int> _numFormats;
  String _stylesTarget, _sharedStringsTarget, _defaultSheet;
  Parser parser;

  Excel._(Archive archive) {
    this._archive = archive;
    _colorChanges = false;
    _mergeChanges = false;
    _sheets = <String, XmlNode>{};
    _xmlFiles = <String, XmlDocument>{};
    _xmlSheetId = <String, String>{};
    _sheetMap = Map<String, Sheet>();
    _cellStyleReferenced = <String, Map<String, int>>{};
    _fontStyleList = List<_FontStyle>();
    _patternFill = List<String>();
    _sharedStrings = List<String>();
    _cellStyleList = List<CellStyle>();
    _mergeChangeLook = List<String>();
    _numFormats = List<int>();
    parser = Parser._(this);
    parser._startParsing();
  }

  factory Excel.createExcel() {
    String newSheet =
        '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';
    return Excel.decodeBytes(Base64Decoder().convert(newSheet));
  }

  factory Excel.decodeBytes(List<int> data,
      {bool verify = false, String password}) {
    if (verify) {
      assert(password != null,
          "Password can't be null.\nEither try setting verify = false or provide password.");
    }

    return _newExcel(
        ZipDecoder().decodeBytes(data, verify: verify, password: password));
  }

  factory Excel.decodeBuffer(InputStream input,
      {bool verify = false, String password}) {
    if (verify) {
      assert(password != null,
          "Password can't be null.\nEither try setting verify = false or provide password.");
    }
    return _newExcel(
        ZipDecoder().decodeBuffer(input, verify: verify, password: password));
  }

  /**
   * 
   * 
   * It will return `tables` as map in order to mimic the previous versions reading the data.
   * 
   * 
   */
  Map<String, Sheet> get tables {
    if (this._sheetMap == null || this._sheetMap.isEmpty) {
      _damagedExcel(text: "Corrupted Excel file.");
    }
    return Map<String, Sheet>.from(this._sheetMap);
  }

  /**
   * 
   * 
   * It will return the SheetObject of `sheet`.
   * 
   * If the `sheet` does not exist then it will create `sheet` with `New Sheet Object`
   * 
   * 
   */
  Sheet operator [](String sheet) {
    _availSheet(sheet);
    return _sheetMap[sheet];
  }

  /**
   * 
   * 
   * Returns the `Map<String, Sheet>`
   * 
   * where `key` is the `Sheet Name` and the `value` is the `Sheet Object`
   * 
   * 
   */
  Map<String, Sheet> get sheets {
    return Map<String, Sheet>.from(_sheetMap);
  }

  /**
   * 
   * 
   * If `sheet` does not exist then it will be automatically created with contents of `sheetObject`
   * 
   * It will clone `oldSHeetObject` to newSheet = `sheet` and both the `newSheetObject` and `oldSheetObject` will not be linked.
   * 
   * 
   */
  operator []=(String sheet, Sheet oldSheetObject) {
    _availSheet(sheet);

    _sheetMap[sheet] = Sheet._clone(this, sheet, oldSheetObject);
  }

  /**
   * 
   * 
   * If `existingSheetName` exist then `sheetName` will be linked with `existingSheetName's` object.
   * 
   * Important Note: After linkage the operations performed on `sheetName`, will also get performed on `existingSheetName` and `vica-versa`.
   * 
   * If `existingSheetName` does not exist then no-linkage will be performed;
   * 
   * 
   */
  void link(String sheetName, Sheet existingSheetName) {
    if (_isContain(_sheetMap[existingSheetName.sheetName])) {
      _availSheet(sheetName);

      _sheetMap[sheetName] = _sheetMap[existingSheetName.sheetName];
    }
  }

  /**
   * 
   * 
   * Changes the name from `oldSheetName` to `newSheetName`.
   * 
   * In order to change name: `oldSheetName` should exist in `excel.tables.keys` and `newSheetName` must not exist.
   * 
   * 
   */
  void rename(String oldSheetName, String newSheetName) {
    if (_isContain(_sheetMap[oldSheetName]) &&
        !_isContain(_sheetMap[newSheetName])) {
      this[newSheetName] = this[oldSheetName];

      ///
      /// delete the oldSheetName as sheet with newSheetName is having cloned SheetObject of oldSheetName with new reference,
      ///  so deleting oldSheetName's Sheet Object
      delete(oldSheetName);
    }
  }

  /**
   * 
   * 
   * If `sheet` exist in `excel.tables.keys` and `excel.tables.keys.length >= 2` then it will be `deleted`.
   * 
   * 
   */
  void delete(String sheet) {
    ///
    /// remove the sheet `name` or `key` from the below locations if they exist.

    ///
    /// If it is not the last sheet then `delete` otherwise `return`;
    if (_sheetMap == null || _sheetMap.length <= 1) {
      return;
    }

    ///
    /// remove the `Sheet Object` from `_sheetMap`.
    if (_isContain(_sheetMap[sheet])) {
      _sheetMap.remove(sheet);
    }

    ///
    /// remove from `_mergeChangeLook`.
    if (_mergeChangeLook.contains(sheet)) {
      _mergeChangeLook.remove(sheet);
    }

    ///
    /// remove from `_xmlSheetId` and set the flag `_rIdCheck` to `true` in order to re-process the _rIds and serialize them.
    if (_isContain(_xmlSheetId[sheet])) {
      _xmlSheetId.remove(sheet);
      // _rIdCheck = true;
    }

    ///
    /// remove from key = `sheet` from `_sheets`
    if (_isContain(_sheets[sheet])) {
      _sheets.remove(sheet);
    }
  }

  /**
   * 
   * 
   * It will start setting the edited values of `sheets` into the `files` and then `exports the file`.
   * 
   * 
   */
  Future<List> encode() async {
    Save s = Save._(this, parser);
    return s._save();
  }

  /**
   * 
   * 
   * returns the name of the `defaultSheet` (the sheet which opens firstly when xlsx file is opened in `excel based software`).
   * 
   * 
   */
  Future<String> getDefaultSheet() async {
    if (_defaultSheet != null) {
      return _defaultSheet;
    } else {
      String re = await _getDefaultSheet();
      return re;
    }
  }

  /**
   * 
   * 
   * Internal function which returns the defaultSheet-Name by reading from `workbook.xml`
   * 
   * 
   */
  Future<String> _getDefaultSheet() async {
    XmlElement _sheet =
        _xmlFiles['xl/workbook.xml'].findAllElements('sheet').first;

    if (_sheet != null) {
      var defaultSheet = _sheet.getAttribute('name');
      if (defaultSheet != null) {
        return defaultSheet.toString();
      } else {
        _damagedExcel(
            text: 'Excel sheet corrupted!! Try creating new excel file.');
      }
    }
    return null;
  }

  /**
   * 
   * 
   * It returns `true` if the passed `sheetName` is successfully set to `default opening sheet` otherwise returns `false`.
   * 
   * 
   */
  Future<bool> setDefaultSheet(String sheetName) async {
    if (_isContain(_sheetMap[sheetName])) {
      _defaultSheet = sheetName;
      return true;
    }
    return false;
  }

  /**
   * 
   * 
   * Inserts an empty `column` in sheet at position = `columnIndex`.
   * 
   * If `columnIndex == null` or `columnIndex < 0` if will not execute 
   * 
   * If the `sheet` does not exists then it will be created automatically.
   * 
   * 
   */
  void insertColumn(String sheet, int columnIndex) {
    if (columnIndex == null || columnIndex < 0) {
      return;
    }
    _availSheet(sheet);
    _sheetMap[sheet].insertColumn(columnIndex);
  }

  /**
   * 
   * 
   * If `sheet` exists and `columnIndex < maxColumns` then it removes column at index = `columnIndex`
   * 
   * 
   */
  void removeColumn(String sheet, int columnIndex) {
    if (columnIndex != null &&
        columnIndex >= 0 &&
        _isContain(_sheetMap[sheet])) {
      _sheetMap[sheet].removeColumn(columnIndex);
    }
  }

  /**
   * 
   * 
   * Inserts an empty row in `sheet` at position = `rowIndex`.
   * 
   * If `rowIndex == null` or `rowIndex < 0` if will not execute 
   * 
   * If the `sheet` does not exists then it will be created automatically.
   * 
   * 
   */
  void insertRow(String sheet, int rowIndex) {
    if (rowIndex != null && rowIndex < 0) {
      return;
    }
    _availSheet(sheet);
    _sheetMap[sheet].insertRow(rowIndex);
  }

  /**
   * 
   * 
   * If `sheet` exists and `rowIndex < maxRows` then it removes row at index = `rowIndex`
   * 
   * 
   */
  void removeRow(String sheet, int rowIndex) {
    if (rowIndex != null && rowIndex >= 0 && _isContain(_sheetMap[sheet])) {
      _sheetMap[sheet].removeRow(rowIndex);
    }
  }

  /**
   * 
   * 
   * Appends [row] iterables just post the last filled index in the [sheet]
   * 
   * If `sheet` does not exist then it will be automatically created.
   * 
   * 
   */
  void appendRow(String sheet, List<dynamic> row) {
    if (row == null || row.length == 0) {
      return;
    }
    _availSheet(sheet);
    int targetRow = _sheetMap[sheet].maxRows;
    insertRowIterables(sheet, row, targetRow);
  }

  /**
   * 
   * 
   * If `sheet` does not exist then it will be automatically created.
   * 
   * Adds the [row] iterables in the given rowIndex = [rowIndex] in [sheet]
   * 
   * [startingColumn] tells from where we should start putting the [row] iterables
   * 
   * [overwriteMergedCells] when set to [true] will over-write mergedCell and does not jumps to next unqiue cell.
   * 
   * [overwriteMergedCells] when set to [false] puts the cell value to next unique cell available by putting the value in merged cells only once and jumps to next unique cell.
   * 
   * 
   */
  void insertRowIterables(String sheet, List<dynamic> row, int rowIndex,
      {int startingColumn = 0, bool overwriteMergedCells = true}) {
    if (rowIndex == null || rowIndex < 0) {
      return;
    }
    _availSheet(sheet);
    _sheetMap['$sheet'].insertRowIterables(row, rowIndex,
        startingColumn: startingColumn,
        overwriteMergedCells: overwriteMergedCells);
  }

  /**
   * 
   * 
   * Returns the `count` of replaced `source` with `target`
   *
   * `source` is dynamic which allows you to pass your custom `RegExp` providing more control over it.
   *
   * optional argument `first` is used to replace the number of first earlier occurrences
   *
   * If `first` is set to `3` then it will replace only first `3 occurrences` of the `source` with `target`.
   * 
   *        excel.findAndReplace('MySheetName', 'sad', 'happy', first: 3);
   * 
   *        or
   * 
   *        var mySheet = excel['mySheetName'];
   *        mySheet.findAndReplace('MySheetName', 'sad', 'happy', first: 3);
   * 
   * In the above example it will replace all the occurences of `sad` with `happy` in the cells
   *
   * Other `options` are used to `narrow down` the `starting and ending ranges of cells`.
   * 
   * 
   */
  int findAndReplace(String sheet, dynamic source, dynamic target,
      {int first = -1,
      int startingRow = -1,
      int endingRow = -1,
      int startingColumn = -1,
      int endingColumn = -1}) {
    int replaceCount = 0;

    return replaceCount;
  }

  /**
   * 
   * 
   * Make `sheet` available if it does not exist in `_sheetMap`
   * 
   * 
   */
  _availSheet(String sheet) {
    if (_sheetMap == null) {
      _sheetMap = Map<String, Sheet>();
    }
    if (!_isContain(_sheetMap[sheet])) {
      _sheetMap[sheet] = Sheet._(this, sheet);
    }
  }

  /**
   * 
   * 
   * Updates the contents of `sheet` of the `cellIndex: CellIndex.indexByColumnRow(0, 0);` where indexing starts from 0
   * 
   * ----or---- by `cellIndex: CellIndex.indexByString("A3");`.
   * 
   * Styling of cell can be done by passing the CellStyle object to `cellStyle`.
   * 
   * If `sheet` does not exist then it will be automatically created.
   * 
   * 
   */
  void updateCell(String sheet, CellIndex cellIndex, dynamic value,
      {CellStyle cellStyle}) {
    if (cellIndex == null) {
      return;
    }
    _availSheet(sheet);

    if (cellStyle != null) {
      _colorChanges = true;
      _sheetMap[sheet].updateCell(cellIndex, value, cellStyle: cellStyle);
    } else {
      _sheetMap[sheet].updateCell(cellIndex, value);
    }
  }

  /**
   * 
   * 
   * Merges the cells starting from `start` to `end`.
   * 
   * If `custom value` is not defined then it will look for the very first available value in range `start` to `end` by searching row-wise from left to right.
   * 
   * If `sheet` does not exist then it will be automatically created.
   * 
   * 
   */
  void merge(String sheet, CellIndex start, CellIndex end,
      {dynamic customValue}) {
    if (start == null || end == null) {
      return;
    }
    _availSheet(sheet);
    _sheetMap[sheet].merge(start, end, customValue: customValue);
  }

  /**
   * 
   * 
   * returns an Iterable of `cell-Id` for the previously merged cell-Ids.
   * 
   * 
   */
  List<String> getMergedCells(String sheet) {
    return _isContain(_sheetMap[sheet])
        ? List<String>.of(_sheetMap[sheet].spannedItems)
        : List<String>();
  }

  /**
   * 
   * 
   * unMerge the merged cells.
   * 
   *        var sheet = 'DesiredSheet';
   *        List<String> spannedCells = excel.getMergedCells(sheet);
   *        var cellToUnMerge = "A1:A2";
   *        excel.unMerge(sheet, cellToUnMerge);
   * 
   * 
   */
  void unMerge(String sheet, String unmergeCells) {
    if (_isContain(_sheetMap[sheet])) {
      _sheetMap[sheet].unMerge(unmergeCells);
    }
  }

  /**
   * 
   * 
   * Internal function taking care of adding the `sheetName` to the `mergeChangeLook` List
   * So that merging function will be only called on `sheetNames of mergeChangeLook`
   * 
   * 
   */
  set _mergeChangeLookup(String value) {
    if (!_mergeChangeLook.contains(value)) {
      _mergeChangeLook.add(value);
    }
  }
}
