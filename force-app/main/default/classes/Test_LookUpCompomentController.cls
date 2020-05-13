/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
/**
  *    Description    :    This Test class check functionality LookUpComponentController
  *  
  *    Created By     :    
  *
  *    Created Date   :    05/01/2020
  *
  *    Version        :    V1.0
  *
  *    Revisison Log  :    V1.0 - Created
  *
  *    Coverage       :     100%
**/   
@isTest(seeAllData = false)
private class Test_LookUpCompomentController {
    static testMethod void myUnitTest() {
        sObject sobj1 = new Account(Name='Trailhead');
        string fieldName = 'Name';
        System.assertEquals('Name',fieldName);
        
        //Test start here
        Test.startTest(); 
        //Initializing the class...
        LookUpCompomentController lcc = new LookUpCompomentController();
        lcc.inputObject = new Account(Name='Trailhead');
        lcc.fieldname = 'Name';
        System.assertEquals('Name',lcc.fieldname);
        lcc.getSField();
        lcc.getFieldDescribe();
        Boolean lc = lcc.isLookup;
        String objName = lcc.objectName;
         
        //Test stop here
        Test.stopTest(); 
        System.assertEquals(false,lc);
    }
}