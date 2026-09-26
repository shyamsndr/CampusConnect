export function validateUserData(data: {
  memberCode: string;
  name: string;
  email: string;
  role: string;
  department: string;
  phone: string;
}): string | null {
  if (!data.memberCode.trim()) {
    return "Member code is required.";
  }

  if (!data.name.trim()) {
    return "Full name is required.";
  }

  if (!data.email.trim()) {
    return "Email address is required.";
  }

  if (!data.role.trim()) {
    return "Role is required.";
  }

  if (!data.department.trim()) {
    return "Department is required.";
  }

  if (!data.phone.trim()) {
    return "Phone number is required.";
  }

  if (!["Student", "Staff"].includes(data.role)) {
    return "Invalid role. Allowed roles: Student, Staff.";
  }

  if (!["MCA", "MBA"].includes(data.department)) {
    return "Invalid department. Allowed departments: MCA, MBA.";
  }

  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

  if (!emailRegex.test(data.email)) {
    return "Invalid email address.";
  }

  return null;
}