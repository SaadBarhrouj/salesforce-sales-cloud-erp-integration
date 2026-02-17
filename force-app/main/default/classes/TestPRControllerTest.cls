/**
 * @description Test class for TestPRController
 */
@isTest
private class TestPRControllerTest {
    @isTest
    static void testConstructor() {
        Test.startTest();
        TestPRController controller = new TestPRController();
        Assert.areNotEqual(null, controller, 'Controller should be instantiated');
        Test.stopTest();
    }
}
