# Assets Folder Structure

This folder contains all the assets used in the Mini Project Helper app.

## Folder Structure:

### `/images/`
Place all image assets here:
- `app_logo.png` - Main app logo for splash screen
- `welcome_bg.jpg` - Background image for welcome screen
- `project_placeholder.png` - Placeholder for project cards

### `/animations/`
Place all Lottie animation files here:
- `welcome_animation.json` - Animation for first intro slide
- `workflow_animation.json` - Animation for second intro slide  
- `learning_animation.json` - Animation for third intro slide
- `loading_animation.json` - Loading animation

### `/icons/`
Place all icon assets here:
- `lightbulb.png` - Topic selection icon
- `timeline.png` - Roadmap icon
- `code.png` - Code generation icon
- `quiz.png` - Viva preparation icon

## Usage:
Reference these assets in your Flutter code using:
```dart
Image.asset('lib/assets/images/app_logo.png')
Lottie.asset('lib/assets/animations/welcome_animation.json')
```

## Note:
For the current implementation, we're using built-in Flutter icons and placeholder containers. You can replace these with actual assets later.