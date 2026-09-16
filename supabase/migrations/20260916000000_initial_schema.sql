create extension if not exists "uuid-ossp";

create table if not exists profiles (
  id uuid references auth.users not null primary key,
  email text,
  full_name text,
  role text check (role in ('ADMIN', 'TEACHER', 'STUDENT')),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create table if not exists classes (
  id uuid default uuid_generate_v4() primary key,
  name text not null,
  section text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create table if not exists students (
  id uuid default uuid_generate_v4() primary key,
  profile_id uuid references profiles(id),
  class_id uuid references classes(id),
  parent_name text,
  phone text,
  address text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create table if not exists fees (
  id uuid default uuid_generate_v4() primary key,
  student_id uuid references students(id),
  amount_paid numeric not null,
  payment_date date not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create table if not exists attendance (
  id uuid default uuid_generate_v4() primary key,
  student_id uuid references students(id),
  date date not null,
  status text check (status in ('PRESENT', 'ABSENT', 'LATE')),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);
