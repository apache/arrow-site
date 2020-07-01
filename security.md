---
layout: default
title: Security
description: Security
---

# Reporting Security Issues

Apache Arrow uses the standard process outlined by the [Apache Security Team](https://www.apache.org/security/) for reporting vulnerabilities. Note that vulnerabilities should not be publicly disclosed until the project has responded.

To report a possible security vulnerability, please email [private@arrow.apache.org](mailto:private@arrow.apache.org).

<hr class="my-5">

### [CVE-2019-12408](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-12408): Uninitialized Memory in C++ ArrayBuilder

**Severity**: High

**Vendor**: The Apache Software Foundation

**Versions affected**: 0.14.x

**Description**: It was discovered that the C++ implementation (which underlies the R, Python and Ruby implementations) of Apache Arrow 0.14.0 to 0.14.1 had a uninitialized memory bug when building arrays with null values in some cases. This can lead to uninitialized memory being unintentionally shared if Arrow Arrays are transmitted over the wire (for instance with Flight) or persisted in the streaming IPC and file formats.

**Mitigation**: Upgrade to version 0.15.1 or greater.

<hr class="my-5">

### [CVE-2019-12410](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-12410): Uninitialized Memory in C++ Reading from Parquet

**Severity**: High

**Vendor**: The Apache Software Foundation

**Versions affected**: 0.12.0 - 0.14.1

**Description**: While investigating UBSAN errors in [ARROW-6549](https://github.com/apache/arrow/pull/5365) it was discovered Apache Arrow versions 0.12.0 to 0.14.1 left memory Array data uninitialized when reading RLE null data from parquet. This affected the C++, Python, Ruby, and R implementations. The uninitialized memory could potentially be shared if are transmitted over the wire (for instance with Flight) or persisted in the streaming IPC and file formats.

**Mitigation**: Upgrade to version 0.15.1 or greater.
