@isTest
private class DestructiveChangesTestClass {
    @isTest static void testHelloWord() {
        String word = sayHelloWorld(); 
        System.assertEquals('Hello World',word);
    }
     static String sayHelloWorld() {
        return 'Hello World';
    }

}