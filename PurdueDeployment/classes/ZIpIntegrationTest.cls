/**
 * The ZIpIntegrationTest class contains unit tests for various scenarios related to ZIP integration.
 */
@isTest
public class ZIpIntegrationTest {
    @TestSetup
    static void makeData() {
        insert new Account(Name = 'testAccount');
        insert new Contact(LastName = 'test');
        insert new Lead(lastName = 'test', Company = 'testCompany');
    }

    /**
     * testInsert validates a single Location Identifier insert.
     */
    @isTest
    public static void testInsert() {
        ZipIntegrationHTTPMockTest mock = new ZipIntegrationHTTPMockTest();
        for (HttpResponse res : responses()) {
            mock.addResponse(res);
        }

        Test.setMock(HttpCalloutMock.class, mock);

        Location_Identifier__c locIdent = new Location_Identifier__c(
            Zip_Code__c = '93727'
        );

        test.startTest();
        insert locIdent;
        test.stopTest();

        locIdent = [
            SELECT Id, City__c, State__c, Country__c
            FROM Location_Identifier__c
            WHERE Id = :locIdent.Id
        ];

        Assert.areEqual(
            'Fresno',
            locIdent.City__c,
            'The city should be Fresno.'
        );
        Assert.areEqual(
            'California',
            locIdent.State__c,
            'The state should be California.'
        );
        Assert.areEqual('US', locIdent.Country__c, 'The country should be US.');
    }

    /**
     * testMultipleInsert validates a list of Location Identifier inserts.
     */
    @isTest
    public static void testMultipleInsert() {
        ZipIntegrationHTTPMockTest mock = new ZipIntegrationHTTPMockTest();
        for (HttpResponse res : responses()) {
            mock.addResponse(res);
        }

        Test.setMock(HttpCalloutMock.class, mock);

        List<Location_Identifier__c> locList = new List<Location_Identifier__c>{
            new Location_Identifier__c(Zip_Code__c = '93727'),
            new Location_Identifier__c(Zip_Code__c = '00000'),
            new Location_Identifier__c(Zip_Code__c = '12345')
        };

        test.startTest();
        insert locList;
        test.stopTest();

        locList = [
            SELECT Id, City__c, State__c, Country__c
            FROM Location_Identifier__c
        ];

        Assert.areEqual(3, locList.size(), 'Should be 3 inserted records.');
        Assert.areEqual(
            'Fresno',
            locList[0].City__c,
            'First record should have City as Fresno.'
        );
        Assert.isNull(locList[1].State__c, 'State should be blank/null.');
    }

    /**
     * testInsert404Response validates a record/data not found response from the mock HTTP interface.
     */
    @isTest
    public static void testInsert404Response() {
        ZipIntegrationHTTPMockTest mock = new ZipIntegrationHTTPMockTest();

        mock.addResponse(responses()[2]);

        Test.setMock(HttpCalloutMock.class, mock);

        Location_Identifier__c locIdent = new Location_Identifier__c(
            Zip_Code__c = '12345'
        );

        test.startTest();
        insert locIdent;
        test.stopTest();

        locIdent = [
            SELECT Id, City__c, State__c, Country__c
            FROM Location_Identifier__c
            WHERE Id = :locIdent.Id
        ];

        Assert.isNull(locIdent.Country__c, 'Country should be blank.');
    }

    /**
     * testUpdate validates that a record will enqueue a callout and update its location data when the Zip code is changed.
     */
    @isTest
    public static void testUpdate() {
        ZipIntegrationHTTPMockTest mock = new ZipIntegrationHTTPMockTest();

        mock.addResponse(responses()[0]);
        mock.addResponse(responses()[0]);

        Test.setMock(HttpCalloutMock.class, mock);

        Location_Identifier__c locIdent = new Location_Identifier__c(
            Zip_Code__c = '00000'
        );

        insert locIdent;

        locIdent = [
            SELECT Id, State__c
            FROM Location_Identifier__c
            WHERE Id = :locIdent.Id
        ];

        Assert.isNull(locIdent.State__c, 'State should be null.');

        test.startTest();
        locIdent.Zip_Code__c = '93727';
        update locIdent;
        test.stopTest();

        Location_Identifier__c locIdent2 = [
            SELECT Id, State__c
            FROM Location_Identifier__c
            WHERE Id = :locIdent.Id
        ];

        Assert.AreEqual(locIdent2.State__c, 'California', 'State should be California now.');
    }

    /**
     * testLWCHandlerSuccess validates that the zipIntegrationLWC_EnterZip handler works as designed.
     */
    @isTest
    public static void testLWCHandlerSuccess() {
        ZipIntegrationHTTPMockTest mock = new ZipIntegrationHTTPMockTest();
        for (HttpResponse res : responses()) {
            mock.addResponse(res);
        }

        Test.setMock(HttpCalloutMock.class, mock);

        String zipCode = '93727';
        String recordId;

        test.startTest();
        ZipIntegrationLWCHandler.createLocationIdentifiers(zipCode, recordId);
        test.stopTest();

        Location_Identifier__c locIdent = [
            SELECT Id, State__c
            FROM Location_Identifier__c
            LIMIT 1
        ];

        Assert.areEqual(
            'California',
            locIdent.State__c,
            'Should have found a record, State should be California.'
        );
    }

    /**
     * testLWCHandlerAccountSuccess validates that the zipIntegrationLWC_EnterZip handler works as designed, and updates a related object record.
     */
    @isTest
    public static void testLWCHandlerAccountSuccess() {
        ZipIntegrationHTTPMockTest mock = new ZipIntegrationHTTPMockTest();
        for (HttpResponse res : responses()) {
            mock.addResponse(res);
        }

        Test.setMock(HttpCalloutMock.class, mock);

        Account a = [SELECT Id FROM Account WHERE Name = 'testAccount' LIMIT 1];

        String zipCode = '93727';
        String recordId = a.Id;

        test.startTest();
        ZipIntegrationLWCHandler.createLocationIdentifiers(zipCode, recordId);
        test.stopTest();

        a = [SELECT Id, BillingCity FROM Account WHERE Id = :a.Id];

        Assert.areEqual(
            'Fresno',
            a.BillingCity,
            'BillingCity should be Fresno.'
        );
    }

    /**
     * testLWCHandlerLeadSuccess validates that the zipIntegrationLWC_EnterZip handler works as designed, and updates a related object record.
     */
    @isTest
    public static void testLWCHandlerLeadSuccess() {
        ZipIntegrationHTTPMockTest mock = new ZipIntegrationHTTPMockTest();
        for (HttpResponse res : responses()) {
            mock.addResponse(res);
        }

        Test.setMock(HttpCalloutMock.class, mock);

        Lead l = [SELECT Id FROM Lead WHERE LastName = 'test' LIMIT 1];

        String zipCode = '93727';
        String recordId = l.Id;

        test.startTest();
        ZipIntegrationLWCHandler.createLocationIdentifiers(zipCode, recordId);
        test.stopTest();

        l = [SELECT Id, City FROM Lead WHERE Id = :l.Id];

        Assert.areEqual('Fresno', l.City, 'City should be Fresno.');
    }

    /**
     * testLWCHandlerContactSuccess validates that the zipIntegrationLWC_EnterZip handler works as designed, and updates a related object record.
     */
    @isTest
    public static void testLWCHandlerContactSuccess() {
        ZipIntegrationHTTPMockTest mock = new ZipIntegrationHTTPMockTest();
        for (HttpResponse res : responses()) {
            mock.addResponse(res);
        }

        Test.setMock(HttpCalloutMock.class, mock);

        Contact c = [SELECT Id FROM Contact WHERE LastName = 'test' LIMIT 1];

        String zipCode = '93727';
        String recordId = c.Id;

        test.startTest();
        ZipIntegrationLWCHandler.createLocationIdentifiers(zipCode, recordId);
        test.stopTest();

        c = [SELECT Id, MailingCity FROM Contact WHERE Id = :c.Id];

        Assert.areEqual('Fresno', c.MailingCity, 'City should be Fresno.');
    }

    /**
     * testLWCHandlerFailure validates that the zipIntegrationLWC_EnterZip returns a failed response, invoking an AuraEnabledException to be shown to end user as toast message.
     */
    @isTest
    public static void testLWCHandlerFailure() {
        ZipIntegrationHTTPMockTest mock = new ZipIntegrationHTTPMockTest();

        HttpResponse resEmpty = new HttpResponse();
        resEmpty.setHeader('Content-Type', 'application/json');
        resEmpty.setBody(
            '{"query":{"codes":["00000"],"country":null},"results":[]}'
        );
        resEmpty.setStatusCode(200);
        mock.addResponse(resEmpty);

        Test.setMock(HttpCalloutMock.class, mock);

        String zipCode = '00000';
        String recordId;

        test.startTest();
        try {
            ZipIntegrationLWCHandler.createLocationIdentifiers(
                zipCode,
                recordId
            );
        } catch (exception e) {
            system.debug('Should have thrown exception ' + e.getMessage());
        }
        test.stopTest();

        Integer locRecords = [SELECT COUNT() FROM Location_Identifier__c];

        Assert.isTrue(locRecords == 0, 'Should not be any records.');
    }

    /**
     * testBulkInsert validates that the bulk handler correctly splits the 150 new records into two batches of 100 and 50 records, then enqueues 2 jobs to handle the data processing.
     */
    @isTest
    public static void testBulkInsert() {
        ZipIntegrationHTTPMockTest mock = new ZipIntegrationHTTPMockTest();

        mock.addResponse(responses()[0]);
        mock.addResponse(responses()[0]);

        Test.setMock(HttpCalloutMock.class, mock);
        List<Location_Identifier__c> locList = new List<Location_Identifier__c>();

        for (Integer i = 0; i < 150; i++) {
            locList.add(new Location_Identifier__c(Zip_Code__c = '93727'));
        }

        test.startTest();
        insert locList;
        test.stopTest();

        locList = [SELECT Id,City__c,State__c,Country__c FROM Location_Identifier__c];
        Boolean b = false;

        Assert.isTrue(locList.size() == 150, 'Should be 250 any records.');
        Integer intg = 0;
        for(Location_Identifier__c loc : locList){

            if(String.isBlank(loc.City__c)){
                intg++;
                b = true;
            }
        }

        System.debug('Here is the integer for test class ' + intg);

        Assert.isFalse(b, 'All records should have updated city.');


    }

    /**
     * The 'responses' method generates a list of mock HTTP responses for use in the above unit tests.
     *
     * @return List of HttpResponse objects representing different HTTP responses (200, 404.).
     */
    public static List<HttpResponse> responses() {
        List<HttpResponse> responses = new List<HttpResponse>();
        HttpResponse resSuccess = new HttpResponse();
        resSuccess.setHeader('Content-Type', 'application/json');
        resSuccess.setBody(
            '{"query":{"codes":["93727"],"country":null},"results":{"93727":[{"postal_code":"93727","country_code":"US","latitude":36.7528,"longitude":-119.7061,"city":"Fresno","state":"California","city_en":"Fresno","state_en":"California","state_code":"CA"}]}}'
        );
        resSuccess.setStatusCode(200);
        responses.add(resSuccess);

        HttpResponse resEmpty = new HttpResponse();
        resEmpty.setHeader('Content-Type', 'application/json');
        resEmpty.setBody(
            '{"query":{"codes":["00000"],"country":null},"results":[]}'
        );
        resEmpty.setStatusCode(200);
        responses.add(resEmpty);

        HttpResponse resFail = new HttpResponse();
        resFail.setHeader('Content-Type', 'application/json');
        resFail.setBody(
            '{"query":{"codes":["12345"],"country":null},"results":[]}'
        );
        resFail.setStatusCode(404);
        responses.add(resFail);

        return responses;
    }
}
