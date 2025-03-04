// Delphi FB4D Library
// Copyright (c) 2018-2025 Christoph Schneider
// Schneider Infosystems AG, Switzerland
// https://github.com/SchneiderInfosystems/FB4D

"use strict";

const functions = require("firebase-functions");

exports.doTest = functions.https.onCall(async (data, context) => {
  const testStr = data.strTest;

  console.log("doTest called with strTest = " + testStr);

  return {res: testStr.toUpperCase()};
});

exports.doTest2 = functions.https.onCall(async (data, context) => {
  const op1 = data.op1;
  const op2 = data.op2;
  const add = op1 + op2;

  console.log("doTest2 called with op1=" + op1 + ", op2=" + op2);

  return {res: add};
});

