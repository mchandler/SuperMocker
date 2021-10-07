/**
 * SuperMocker provides developers with a way to mock specific method calls
 * of an Apex object to simplify Unit Tests and to ensure that tests are
 * isolating the systems and classes under testing.
 * <p>
 *     Usage:
 *     SuperMocker.getInstance().mock(CreditCardProvider.class).mockMethod('chargeCard', true).getObject();
 */
@IsTest
public class SuperMocker {

    private SuperMocker superMocker;
    private Type mockedType;
    private Map<String, Object> mockDirectives = new Map<String, Object>();

    private SuperMocker() {
        // my constructor is deliberately private to require the use of the getInstance() method
    }

    private void setMocker(SuperMocker superMocker) {
        this.superMocker = superMocker;
    }

    private void setType(Type mockType) {
        this.mockedType = mockType;
    }

    /**
     * This is the first step to instantiate a SuperMocker instance.
     *
     * @return SuperMockerLoader
     */
    public static SuperMockerLoader getInstance() {
        SuperMocker superMocker = new SuperMocker();
        superMocker.setMocker(superMocker);

        SuperMockerLoader loader = new SuperMockerLoader(superMocker);
        return loader;
    }

    /**
     * @param methodName String - identify the name of the method you are mocking
     * @param mockReturnValue Object - provide a mocked return value for this method
     *
     * @return the same instance of SuperMocker
     */
    public SuperMocker mockMethod(String methodName, Object mockReturnValue) {
        mockDirectives.put(methodName.toUpperCase(), mockReturnValue);
        return this;
    }

    /**
     * @return Returns the mocked object for use in Apex Test Classes
     */
    public Object getObject() {
        StubbedMock mock = new StubbedMock(mockedType, mockDirectives);
        return Test.createStub(mockedType, mock);
    }

    public class SuperMockerLoader {

        private SuperMocker superMocker;

        public SuperMockerLoader(SuperMocker superMocker) {
            this.superMocker = superMocker;
        }

        /**
         * @param mockType The TYPE of the Apex class you need to mock.
         *
         * @return Returns an instance of SuperMocker
         */
        public SuperMocker mock(Type mockType) {
            this.superMocker.setType(mockType);
            return this.superMocker;
        }
    }

    public class StubbedMock implements System.StubProvider {

        private Type mockedType;
        private Map<String, Object> mockDirectives;

        public StubbedMock(Type mockedType, Map<String, Object> mockDirectives) {
            this.mockedType = mockedType;
            this.mockDirectives = mockDirectives;
        }

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, List<Object> listOfArgs) {
            Set<String> mockedMethods = this.mockDirectives.keySet();

            if (!mockedMethods.contains(stubbedMethodName.toUpperCase())) {
                throw new SuperMockerException('This method has not been mocked: ' + stubbedMethodName);
            }

            Object mockedResponse = this.mockDirectives.get(stubbedMethodName.toUpperCase());
            String mockedResponseType = getObjectType(mockedResponse);

            // Only proceed if the return type of the method matches the type of the mocked response - otherwise, be sad
            if (!mockedResponseType.toUpperCase().equals(returnType.toString().toUpperCase())) {
                throw new SuperMockerException('Method ' + stubbedMethodName + ' incorrectly mocked as ' + mockedResponseType + ' but should be ' + returnType.toString());
            }

            return mockedResponse;
        }

        private String getObjectType(Object evalObject) {
            String result = 'Datetime';

            try{
                Datetime typeCheck = (Datetime) evalObject;
            } catch(System.TypeException te){
                String message = te.getMessage().substringAfter('Invalid conversion from runtime type ');
                result = message.substringBefore(' to Datetime');
            }

            return result;
        }
    }

    public class SuperMockerException extends Exception {}

}
