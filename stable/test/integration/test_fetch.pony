use "ponytest"
use "process"
use ".."

class TestFetchBad is UnitTest
  new iso create() => None

  fun name(): String => "integration_run.TestFetchBad"

  fun apply(h: TestHelper) =>
    h.long_test(1_000_000_000)
    let notifier: ProcessNotify iso = _ExpectClient(h,
      None, // stdout
      [ "No bundle.json in current working directory or ancestors." ],
      0)
    _Exec(h, "stable fetch", consume notifier)

// TODO: fetch something real, add assertions on outcome
