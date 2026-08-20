final: prev: {
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (python-final: python-prev: {
      qasync = python-prev.qasync.overridePythonAttrs (old: {
        disabledTestPaths = [ ];
        disabledTests = (old.disabledTests or [ ]) ++ [
          "test_no_stale_reference_as_argument"
          "test_no_stale_reference_as_result"
        ];
        env = (old.env or { }) // {
          QT_QPA_PLATFORM = "offscreen";
        };
      });
    })
  ];
}
