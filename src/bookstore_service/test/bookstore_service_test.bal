// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

package bookstore_service;

import ballerina/net.http;
import ballerina/test;

@test:BeforeSuite
function beforeFunc () {
    // Start the 'bookstoreService' before running the test
    _ = test:startServices("bookstore_service");
}

// Client endpoint
endpoint http:ClientEndpoint clientEP {
    targets:[{uri:"http://localhost:9090/bookstore"}]
};

// Function to test 'getBookList' resource
@test:Config
function testResourceGetBookList () {
    // Initialize the empty http request
    http:Request request = {};

    // Send a 'get' request and obtain the response
    http:Response response =? clientEP -> get("/getBookList", request);
    // Expected response code is 200
    test:assertEquals(response.statusCode, 200, msg = "bookstore service did not respond with 200 OK signal!");
    // Check whether the response is as expected
    json resPayload =? response.getJsonPayload();
    test:assertTrue(resPayload.toString().contains("Lolita"), msg = "Response mismatch!");
}

// Function to test 'placeOrder' resource
@test:Config
function testResourcePlaceOrder () {
    // Initialize the empty http request
    http:Request request = {};

    // Construct a request payload
    request.setJsonPayload({"Name":"Alice", "Address":"20, Palm Grove, Colombo, Sri Lanka",
                               "ContactNumber":"+94777123456", "BookName":"The Rainbow"});
    // Send a 'post' request and obtain the response
    http:Response response =? clientEP -> post("/placeOrder", request);
    // Expected response code is 200
    test:assertEquals(response.statusCode, 200, msg = "bookstore service did not respond with 200 OK signal!");
    // Check whether the response is as expected
    json resPayload =? response.getJsonPayload();
    json expected = {"Message":"Your order is successfully placed. Ordered book will be delivered soon"};
    test:assertEquals(resPayload, expected, msg = "Response mismatch!");
}
