I'll explain them the same way we approached the schema—from the perspective of designing a real production database instead of memorizing definitions.

---

# Database Normalization

Imagine you're designing a database for a real company.

Every decision you make affects:

* storage
* performance
* maintainability
* data consistency
* future development

Normalization is simply a set of design rules that help eliminate bad database design.

Think of it as progressively improving a schema.

```
Raw Data
    ↓
1NF
    ↓
2NF
    ↓
3NF
```

Every level removes a different class of problems.

---

# Before Normalization (Unnormalized Form - UNF)

Suppose someone designs an orders table like this.

| Order ID | Customer | Products                |
| -------- | -------- | ----------------------- |
| 101      | Alice    | Laptop, Mouse, Keyboard |
| 102      | Bob      | Monitor, HDMI Cable     |

Looks okay?

Not really.

The Products column contains multiple values.

```
Laptop

Mouse

Keyboard
```

inside a single cell.

This creates many problems.

You cannot easily:

* search for every Mouse
* delete only Keyboard
* count products
* join products with another table

This violates the most basic relational rule.

---

# First Normal Form (1NF)

## Definition

Every column must contain a single (atomic) value.

No repeating groups.

Every row must be uniquely identifiable.

The keyword is

> Atomic

One cell = One value.

---

## Bad Example

| Student | Subjects               |
| ------- | ---------------------- |
| John    | Math, Science, English |

The Subjects column stores three values.

Not allowed.

---

## Correct Version

Split it into multiple rows.

| Student | Subject |
| ------- | ------- |
| John    | Math    |
| John    | Science |
| John    | English |

Now every cell contains exactly one value.

This satisfies 1NF.

---

## Another Example

Bad

| Employee | Phone Numbers          |
| -------- | ---------------------- |
| Alice    | 9876543210, 9999999999 |

Correct

| Employee | Phone      |
| -------- | ---------- |
| Alice    | 9876543210 |
| Alice    | 9999999999 |

---

## What about JSONB?

Many students think JSON violates 1NF.

Example

```json
{
  "priority":"High",
  "labels":["Backend","Urgent"]
}
```

stored in

```
metadata JSONB
```

Does this violate 1NF?

No.

Why?

Because PostgreSQL treats JSONB as a single supported data type.

The database sees:

```
metadata

↓

One Value
```

Internally it contains structured data, but relationally it's still one value.

So JSONB does **not** automatically violate 1NF.

---

## Our ProjectFlow Schema

Users

```
id

name

email
```

Every column stores one value.

Projects

```
id

owner_id

name
```

One value.

Tasks

```
title

status

metadata(JSONB)
```

Still one value per column.

Therefore

```
ProjectFlow

↓

1NF ✔
```

---

# Why 1NF Exists

Without 1NF, SQL becomes painful.

Imagine finding everyone who bought a Mouse.

If Products is

```
Laptop,Mouse,Keyboard
```

You'd need string searching.

Terrible.

Instead,

```
Order Items

↓

One Product Per Row
```

Now SQL becomes easy.

```sql
SELECT *
FROM order_items
WHERE product='Mouse';
```

Much cleaner.

---

# Second Normal Form (2NF)

Most people memorize:

> No partial dependency.

But what does that actually mean?

It only matters when a table has a **composite primary key**.

If your table has a single-column primary key,

2NF is automatically satisfied.

---

## Composite Primary Key

Example

```
(student_id, subject_id)
```

Together they uniquely identify a row.

Neither column alone is unique.

---

Suppose we create

| Student | Subject | Student Name |
| ------- | ------- | ------------ |
| 1       | Math    | Alice        |
| 1       | Physics | Alice        |
| 1       | English | Alice        |

Primary key

```
(student_id, subject_id)
```

Now ask:

Does Student Name depend on

```
student_id

AND

subject_id
```

No.

It only depends on

```
student_id
```

Because regardless of the subject,

Student 1 is always Alice.

This is called a

**Partial Dependency**.

Part of the primary key determines another column.

That violates 2NF.

---

## Correct Design

Students

| student_id | student_name |
| ---------- | ------------ |
| 1          | Alice        |

Enrollments

| student_id | subject_id |
| ---------- | ---------- |
| 1          | Math       |
| 1          | Physics    |
| 1          | English    |

Now

```
student_name
```

belongs in Students.

No duplication.

2NF satisfied.

---

## Another Example

Bad

| Product ID | Warehouse ID | Product Name |
| ---------- | ------------ | ------------ |
| 10         | A            | Laptop       |
| 10         | B            | Laptop       |

Primary key

```
(product_id, warehouse_id)
```

Product Name depends only on Product ID.

Not Warehouse.

Violation.

Move Product Name into Products table.

---

## Our ProjectFlow Example

Composite key

```
(project_id,user_id)
```

in

```
project_members
```

Other columns

```
role_in_project

joined_at
```

Do they depend only on

```
project_id
```

No.

Do they depend only on

```
user_id
```

No.

A user's role is specific to **that project membership**.

For example:

| Project    | User  | Role      |
| ---------- | ----- | --------- |
| Website    | Alice | Manager   |
| Mobile App | Alice | Developer |

Alice has different roles in different projects.

So

```
role_in_project
```

depends on

```
(project_id,user_id)
```

the whole key.

Not part of it.

Therefore

```
ProjectFlow

↓

2NF ✔
```

---

# Why 2NF Exists

It removes unnecessary duplication.

Without it

```
Alice

Alice

Alice

Alice

Alice
```

would appear hundreds of times.

If Alice changes her name,

you'd have to update hundreds of rows.

That's called an

**Update Anomaly**.

2NF prevents this.

---

# Third Normal Form (3NF)

Now assume we've already achieved:

* 1NF
* 2NF

There is still another problem.

Some columns depend on **other non-key columns**.

This is called a

**Transitive Dependency**.

---

## Example

| Employee ID | Department ID | Department Name |
| ----------- | ------------- | --------------- |
| 1           | 5             | HR              |
| 2           | 5             | HR              |
| 3           | 2             | Finance         |

Primary key

```
employee_id
```

Now ask

Does Department Name depend directly on Employee ID?

No.

It depends on

```
department_id
```

Relationship

```
employee_id

↓

department_id

↓

department_name
```

Department Name is determined through another non-key column.

That's a transitive dependency.

Violation of 3NF.

---

## Correct Design

Employees

| Employee ID | Department ID |
| ----------- | ------------- |
| 1           | 5             |
| 2           | 5             |
| 3           | 2             |

Departments

| Department ID | Department Name |
| ------------- | --------------- |
| 5             | HR              |
| 2             | Finance         |

Now

Department Name exists once.

No duplication.

---

## Another Example

Bad Orders table

| Order ID | Customer ID | Customer Name |
| -------- | ----------- | ------------- |

Customer Name depends on

```
Customer ID
```

not

```
Order ID
```

So create

Customers

```
customer_id

customer_name
```

Orders

```
order_id

customer_id
```

---

## Our ProjectFlow Schema

Imagine adding

```
tasks

project_name
```

Would that be okay?

No.

Because

```
task

↓

project_id

↓

project_name
```

Project Name belongs in

```
projects
```

Similarly,

adding

```
owner_email
```

to Tasks would be wrong.

Why?

```
task

↓

project

↓

owner

↓

email
```

The task doesn't own the email.

The Users table does.

So we never duplicate:

* project name
* owner name
* owner email
* assignee email

We store only the foreign key.

Everything else is obtained with a JOIN.

Therefore

```
ProjectFlow

↓

3NF ✔
```

---

# Why 3NF Exists

It prevents:

* Update anomalies (changing a department name in hundreds of rows)
* Insert anomalies (can't add a department until an employee exists)
* Delete anomalies (deleting the last employee accidentally removes all knowledge of the department)

By separating entities into their own tables, each fact is stored exactly once.

---

# Quick Memory Trick

### 1NF

One cell = One value.

```
❌ Math,Science

✔ Math
✔ Science
```

---

### 2NF

Every non-key column depends on the **whole** primary key.

```
(student_id, subject_id)

↓

grade ✔

student_name ❌
```

---

### 3NF

Non-key columns must not depend on other non-key columns.

```
employee_id

↓

department_id

↓

department_name ❌
```

Store `department_name` in the `departments` table instead.

---

# Final Summary

| Normal Form | Removes                                   | Key Question                                                               |
| ----------- | ----------------------------------------- | -------------------------------------------------------------------------- |
| **1NF**     | Repeating groups and multi-valued columns | Does every cell contain exactly one value?                                 |
| **2NF**     | Partial dependencies                      | Does every non-key column depend on the entire primary key?                |
| **3NF**     | Transitive dependencies                   | Does every non-key column depend only on the primary key and nothing else? |

A well-designed production schema like **ProjectFlow** satisfies all three, making it easier to maintain, less error-prone, and more efficient over the lifetime of the application.





This is one of the most misunderstood normalization rules. Let's build it from the ground up.

---

# First, what is a Functional Dependency (FD)?

A functional dependency means:

> If I know **A**, I can determine **B**.

Written as:

```text
A → B
```

Example:

```text
Student_ID → Student_Name
```

If you know:

```text
Student_ID = 101
```

you always know

```text
Student_Name = John
```

because one student ID belongs to one student.

---

Another example:

```text
Email → User
```

If emails are unique,

```text
john@gmail.com
```

always refers to exactly one user.

So

```text
Email → User_ID
Email → Full_Name
Email → Created_At
```

---

# What is a Determinant?

The **left side** of a functional dependency is called the determinant.

Example:

```text
Student_ID → Name
```

Determinant:

```text
Student_ID
```

Example:

```text
Email → Full_Name
```

Determinant:

```text
Email
```

---

# What is a Candidate Key?

A candidate key is:

> The smallest set of columns that uniquely identifies every row.

Example:

Users

| id | email                             | name  |
| -- | --------------------------------- | ----- |
| 1  | [a@gmail.com](mailto:a@gmail.com) | Alice |
| 2  | [b@gmail.com](mailto:b@gmail.com) | Bob   |

Here

```text
id
```

uniquely identifies every row.

Also

```text
email
```

is UNIQUE.

So there are **two candidate keys**.

```text
id
email
```

The primary key is simply the candidate key we chose as the official PK.

---

# Now BCNF

BCNF says

> Every determinant must be a candidate key.

In other words

Whenever

```text
A → B
```

exists,

A must uniquely identify rows.

---

Let's use your schema.

## Users

```sql
users
-------
id
email UNIQUE
full_name
```

Functional dependencies are

```text
id → email
id → full_name

email → id
email → full_name
```

Determinants:

```text
id
email
```

Both are candidate keys.

BCNF satisfied.

---

## Projects

```sql
projects
---------
id
owner_id
name
```

Dependency

```text
id → owner_id
id → name
id → description
```

Determinant

```text
id
```

Primary key.

BCNF satisfied.

---

## Tasks

```sql
tasks
------
id
title
status
due_date
```

Dependency

```text
id → title
id → status
id → due_date
```

Again

```text
id
```

is the determinant.

Primary key.

BCNF.

---

# A BCNF Violation

Imagine this table.

```text
Employee

Employee_ID
Department
Manager
```

Suppose every department has exactly one manager.

Example

| Employee | Department | Manager |
| -------- | ---------- | ------- |
| 1        | IT         | Alice   |
| 2        | IT         | Alice   |
| 3        | HR         | Bob     |

Now we have

```text
Department → Manager
```

because

IT always means Alice.

But

```text
Department
```

is NOT unique.

Many employees belong to IT.

So

```text
Department
```

is **not** a candidate key.

BCNF is violated.

---

Why is that bad?

Imagine Alice changes.

You must update

```text
IT Alice
```

everywhere.

| Employee | Department | Manager |
| -------- | ---------- | ------- |
| 1        | IT         | Charlie |
| 2        | IT         | Alice   |

Now the database contradicts itself.

---

Correct design:

Departments

| Department | Manager |
| ---------- | ------- |
| IT         | Alice   |
| HR         | Bob     |

Employees

| Employee | Department |
| -------- | ---------- |
| 1        | IT         |
| 2        | IT         |
| 3        | HR         |

Now

```text
Department → Manager
```

exists only in the Departments table.

Department is the primary key there.

BCNF satisfied.

---

# Another Example

Bad table

|Student|Course|Professor|

Suppose

Every course has one professor.

Then

```text
Course → Professor
```

But

```text
Course
```

is not unique.

Many students take the same course.

BCNF violation.

Split into

Courses

|Course|Professor|

Enrollment

|Student|Course|

Now BCNF.

---

# Your Schema

Let's inspect every table.

### users

```text
id → everything
email → everything
```

Both keys.

BCNF.

---

### projects

```text
id → everything
```

Primary key.

BCNF.

---

### tasks

```text
id → everything
```

Primary key.

BCNF.

---

### comments

```text
id → everything
```

Primary key.

BCNF.

---

### attachments

```text
id → everything
```

Primary key.

BCNF.

---

### project_members

Primary key

```text
(user_id, project_id)
```

Dependency

```text
(user_id, project_id)
→
role
joined_at
```

Composite primary key is the determinant.

BCNF.

---

# Why people say

> "All determinants are candidate keys."

Because that's literally the BCNF rule.

If every dependency in your database starts from

* a primary key, or
* another unique candidate key,

then no non-key column determines other columns.

That eliminates the update, insert, and delete anomalies BCNF is designed to prevent.

---

## A subtle point about your schema

The statement:

> "Every functional dependency in our schema is based on primary keys or unique keys."

assumes there are **no additional business rules** creating hidden dependencies.

For example, if your business later says:

```text
project_id → owner_id
```

and also enforces that each project has exactly one owner (which it already does), that's fine because `project_id` is the primary key. But if you added a rule like:

```text
role_in_project = 'Owner' → user_id
```

without enforcing it through a candidate key, you'd need to re-evaluate the design. BCNF depends on **all functional dependencies**, including those implied by business rules, not just the ones declared with SQL constraints.
