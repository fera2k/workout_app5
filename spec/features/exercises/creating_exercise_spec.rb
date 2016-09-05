require "rails_helper"

RSpec.feature "Creating Exercise" do
  before do
    @john = User.create(email: "john@example.com", password: "password", first_name: "John", last_name: "Doe")
    login_as(@john)
    
    @exercise = @john.exercises.create!(duration_in_min: 55, workout: 'Duplicate workout', workout_date: 3.days.ago.to_date)
    
    visit "/"

    click_link "My Lounge"
    click_link "New Workout"
    expect(page).to have_link("Back")
  end
  
  scenario "with valid inputs" do
    fill_in "Duration", with: 70
    fill_in "Workout details", with: "Weight lifting"
    fill_in "Activity date", with: 3.days.ago
    click_button "Create Exercise"
    
    expect(page).to have_content("Exercise has been created")
    
    exercise = @john.exercises.reload.last
    expect(current_path).to eq(user_exercise_path(@john, exercise))
    expect(exercise.user_id).to eq(@john.id)
  end
  
  scenario "with invalid inputs" do
    fill_in "Duration", with: ""
    fill_in "Workout details",  with: ""
    fill_in "Activity date",  with: ""
    click_button "Create Exercise"

    expect(page).to have_content("Exercise has not been created")
    expect(page).to have_content("Duration in min is not a number")
    expect(page).to have_content("Workout details can't be blank")
    expect(page).to have_content("Activity date can't be blank")
  end
  
  scenario "with activity date over 7 days old does not show on page" do
    fill_in "Duration", with: 70
    fill_in "Workout details", with: "Weight lifting"
    fill_in "Activity date", with: 8.days.ago
    click_button "Create Exercise"
    
    within("h1") do
      expect(page).to have_content("No exercises found for this period")
    end

    expect(page).to have_link("Back")
  end
  
  scenario "with a future activity date fails" do
    fill_in "Duration", with: 70
    fill_in "Workout details", with: "Weight lifting"
    fill_in "Activity date", with: 1.day.from_now
    click_button "Create Exercise"
    
    expect(page).to have_content("Activity date can't be in the future")
  end
  
  scenario "with same activity date as another fails" do
    expect(@john.exercises.count).to eq(1)

    fill_in "Duration", with: 70
    fill_in "Workout details", with: "Weight lifting"
    fill_in "Activity date", with: 3.days.ago.to_date
    click_button "Create Exercise"

    expect(@john.exercises.count).to eq(1)

    updated_exercise =  @john.exercises.last

    expect(page).to have_content(updated_exercise.duration_in_min)
    expect(page).to have_content(updated_exercise.workout)
    expect(page).to have_content(updated_exercise.workout_date)

    expect(page).not_to have_content(@exercise.duration_in_min)
    expect(page).not_to have_content(@exercise.workout)
  end

end