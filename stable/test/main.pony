use "ponytest"
use integration = "integration"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)

  fun tag tests(test: PonyTest) =>
    test(TestBundle)

    test(integration.TestUsage("")) // no arguments
    test(integration.TestUsage("help"))
    test(integration.TestUsage("unknown arguments"))
    test(integration.TestVersion)

    // these expect to be run in certain testdata directories
    // see the top-level Makefile's integration target
    test(integration.TestFetchBad)
