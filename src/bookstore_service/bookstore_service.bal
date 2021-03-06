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

import ballerina/log;
import ballerina/net.http;
import ballerina/net.jms;

// Struct to construct a book order
struct bookOrder {
    string customerName;
    string address;
    string contactNumber;
    string orderedBookName;
}

// Global variable containing all the available books
json[] bookInventory = ["Tom Jones", "The Rainbow", "Lolita", "Atonement", "Hamlet"];

// JMS client properties
// 'providerUrl' or 'configFilePath', and the 'initialContextFactory' vary according to the JMS provider you use
// 'Apache ActiveMQ' has been used as the message broker in this example
endpoint jms:ClientEndpoint jmsProducerEP {
    initialContextFactory:"org.apache.activemq.jndi.ActiveMQInitialContextFactory",
    providerUrl:"tcp://localhost:61616"
};

// Service endpoint
endpoint http:ServiceEndpoint bookstoreEP {
    port:9090
};

// Book store service, which allows users to order books online for delivery
@http:ServiceConfig {basePath:"/bookstore"}
service<http:Service> bookstoreService bind bookstoreEP {
    // Resource that allows users to place an order for a book
    @http:ResourceConfig {methods:["POST"], consumes:["application/json"], produces:["application/json"]}
    placeOrder (endpoint client, http:Request request) {
        http:Response response = {};
        bookOrder newOrder = {};
        json reqPayload;

        // Try parsing the JSON payload from the request
        match request.getJsonPayload() {
        // Valid JSON payload
            json payload => reqPayload = payload;
        // NOT a valid JSON payload
            any| null => {
                response.statusCode = 400;
                response.setJsonPayload({"Message":"Invalid payload - Not a valid JSON payload"});
                _ = client -> respond(response);
                return;
            }
        }

        json name = reqPayload.Name;
        json address = reqPayload.Address;
        json contact = reqPayload.ContactNumber;
        json bookName = reqPayload.BookName;

        // If payload parsing fails, send a "Bad Request" message as the response
        if (name == null || address == null || contact == null || bookName == null) {
            response.statusCode = 400;
            response.setJsonPayload({"Message":"Bad Request - Invalid payload"});
            _ = client -> respond(response);
            return;
        }

        // Order details
        newOrder.customerName = name.toString();
        newOrder.address = address.toString();
        newOrder.contactNumber = contact.toString();
        newOrder.orderedBookName = bookName.toString().trim();

        // boolean variable to track the availability of a requested book
        boolean isBookAvailable;
        // Check whether the requested book available
        foreach book in bookInventory {
            if (newOrder.orderedBookName.equalsIgnoreCase(book.toString())) {
                isBookAvailable = true;
                break;
            }
        }

        json responseMessage;
        // If requested book is available then try adding the order to the JMS queue 'OrderQueue'
        if (isBookAvailable) {
            var bookOrderDetails =? <json>newOrder;
            // Create a JMS message
            jms:Message queueMessage = jmsProducerEP.createTextMessage(bookOrderDetails.toString());
            // Send the message to the JMS queue
            jmsProducerEP -> send("OrderQueue", queueMessage);
            // Construct a success message for the response
            responseMessage = {"Message":"Your order is successfully placed. Ordered book will be delivered soon"};
            log:printInfo("New order added to the JMS Queue; CustomerName: '" + newOrder.customerName
                          + "', OrderedBook: '" + newOrder.orderedBookName + "';");
        }
        else {
            // If book is not available, construct a proper response message to notify user
            responseMessage = {"Message":"Requested book not available"};
        }

        // Send response to the user
        response.setJsonPayload(responseMessage);
        _ = client -> respond(response);
    }

    // Resource that allows users to get a list of all the available books
    @http:ResourceConfig {methods:["GET"], produces:["application/json"]}
    getBookList (endpoint client, http:Request request) {
        http:Response response = {};
        // Send json array 'bookInventory' as the response, which contains all the available books
        response.setJsonPayload(bookInventory);
        _ = client -> respond(response);
    }
}
