---
layout: default
title: Security
description: Security
---

# Reporting Security Issues

We take security seriously and would like our project to be as robust and
dependable as possible. If you believe to have found a security bug, please do
not file a public issue.

First, please carefully read the Apache Arrow
[Security Model](https://arrow.apache.org/docs/dev/format/Security.html)
and understand its implications, as some apparent security issues can actually
be usage issues.

Second, please follow the standard [vulnerability reporting process](https://apache.org/security/#reporting-a-vulnerability)
outlined by the Apache Software Foundation. We will assess your report, follow
up with our evaluation of the issue, and fix it as soon as possible if we deem
it to be an actual security vulnerability.

<hr class="my-5">

### [CVE-2023-47248](https://www.cve.org/CVERecord?id=CVE-2023-47248): Arbitrary code execution when loading a malicious data file in PyArrow

**Severity**: Critical

**Vendor**: The Apache Software Foundation

**Versions affected**: 0.14.0 to 14.0.0

**Description**: Deserialization of untrusted data in IPC and Parquet readers
in PyArrow versions 0.14.0 to 14.0.0 allows arbitrary code execution.
An application is vulnerable if it reads Arrow IPC, Feather or Parquet data
from untrusted sources (for example user-supplied input files).

**Mitigation**: Upgrade to version 14.0.1 or greater. If not possible, use the
provided [hotfix package](https://pypi.org/project/pyarrow-hotfix/).

### [CVE-2019-12408](https://www.cve.org/CVERecord?id=CVE-2019-12408): Uninitialized Memory in C++ ArrayBuilder

**Severity**: High

**Vendor**: The Apache Software Foundation

**Versions affected**: 0.14.x

**Description**: It was discovered that the C++ implementation (which underlies the R, Python and Ruby implementations) of Apache Arrow 0.14.0 to 0.14.1 had a uninitialized memory bug when building arrays with null values in some cases. This can lead to uninitialized memory being unintentionally shared if Arrow Arrays are transmitted over the wire (for instance with Flight) or persisted in the streaming IPC and file formats.

**Mitigation**: Upgrade to version 0.15.1 or greater.

### [CVE-2019-12410](https://www.cve.org/CVERecord?id=CVE-2019-12410): Uninitialized Memory in C++ Reading from Parquet

**Severity**: High

**Vendor**: The Apache Software Foundation

**Versions affected**: 0.12.0 - 0.14.1

**Description**: While investigating UBSAN errors in [ARROW-6549](https://github.com/apache/arrow/pull/5365) it was discovered Apache Arrow versions 0.12.0 to 0.14.1 left memory Array data uninitialized when reading RLE null data from parquet. This affected the C++, Python, Ruby, and R implementations. The uninitialized memory could potentially be shared if are transmitted over the wire (for instance with Flight) or persisted in the streaming IPC and file formats.

**Mitigation**: Upgrade to version 0.15.1 or greater.
