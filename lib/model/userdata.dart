enum Gender{
  m,
  f,
  d,
}

class UserData {
  String name;
  DateTime birthDate;
  double heightInCM;
  double weightInKG;
  Gender gender;
  int dailyGoal;
  int restingHeartRate;

  UserData(this.name, this.birthDate, this.heightInCM, this.weightInKG, this.gender, this.dailyGoal, this.restingHeartRate);
}
