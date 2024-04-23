# Creates redirect URLS
import os


urls = [
    "contributor-guide/index.html",
    "contributor-guide/architecture.html",
    "contributor-guide/quarterly_roadmap.html",
    "contributor-guide/specification/index.html",
    "contributor-guide/specification/invariants.html",
    "contributor-guide/specification/output-field-name-semantic.html",
    "contributor-guide/communication.html",
    "contributor-guide/roadmap.html",
#    "index.html",
    "user-guide/example-usage.html",
    "user-guide/dataframe.html",
    "user-guide/cli/index.html",
    "user-guide/cli/datasources.html",
    "user-guide/cli/overview.html",
    "user-guide/cli/installation.html",
    "user-guide/cli/usage.html",
    "user-guide/configs.html",
    "user-guide/expressions.html",
    "user-guide/introduction.html",
    "user-guide/faq.html",
    "user-guide/sql/select.html",
    "user-guide/sql/scalar_functions.html",
    "user-guide/sql/index.html",
    "user-guide/sql/ddl.html",
    "user-guide/sql/subqueries.html",
    "user-guide/sql/information_schema.html",
    "user-guide/sql/aggregate_functions.html",
    "user-guide/sql/data_types.html",
    "user-guide/sql/dml.html",
    "user-guide/sql/explain.html",
    "user-guide/sql/operators.html",
    "user-guide/sql/sql_status.html",
    "user-guide/sql/write_options.html",
    "user-guide/sql/window_functions.html",
    "library-user-guide/using-the-dataframe-api.html",
    "library-user-guide/using-the-sql-api.html",
    "library-user-guide/index.html",
    "library-user-guide/profiling.html",
    "library-user-guide/custom-table-providers.html",
    "library-user-guide/building-logical-plans.html",
    "library-user-guide/catalogs.html",
    "library-user-guide/adding-udfs.html",
    "library-user-guide/extending-operators.html",
    "library-user-guide/working-with-exprs.html",
]

for url in urls:
    print ("Processing", url)
    local_file =  os.path.splitext(url)[0]+'.md'
    redirect_url = "https://datafusion.apache.org/{}".format(url)
    print("  local_file:", local_file)
    print("  redirect_url:", redirect_url)
    content = """---
layout: article
title: Apache DataFusion Redirect
description: Link to the Apache Arrow DataFusion project (formerly a sub project of Apache Arrow)
redirect_to: {redirect_url}
redirect_from: datafusion/{url}
---
<!--
{{% comment %}}
Licensed to the Apache Software Foundation (ASF) under one or more
contributor license agreements.  See the NOTICE file distributed with
this work for additional information regarding copyright ownership.
The ASF licenses this file to you under the Apache License, Version 2.0
(the "License"); you may not use this file except in compliance with
the License.  You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
{{% endcomment %}}
-->

<!-- Content to show if the redirect above is not followed -->

Moved to {redirect_url}
""".format(redirect_url=redirect_url, url=url)


    dirname = os.path.dirname(local_file)
    print("  dirname: ", dirname)
    if not os.path.exists(dirname):
        os.makedirs(dirname)
    with open(local_file, "w") as f:
        f.write(content)
