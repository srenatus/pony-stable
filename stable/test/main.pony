use "ponytest"
use integration = "integration"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)

  fun tag tests(test: PonyTest) =>
    test(TestBundle)

    test(integration.TestUsage)
    test(integration.TestVersion)