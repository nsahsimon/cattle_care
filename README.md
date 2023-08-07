## Problem 1: if you run into an error about not being able to compile a file in t
C:\Users\SMARTECH\AppData\Local\Pub\Cache\hosted\pub.dev\tflite-1.1.2\android\build.gradle

solution: change:
    dependencies {
        compile 'org.tensorflow:tensorflow-lite:+'
        compile 'org.tensorflow:tensorflow-lite-gpu:+'
    }

to:
    dependencies {
        implementation 'org.tensorflow:tensorflow-lite:+'
        implementation 'org.tensorflow:tensorflow-lite-gpu:+'
    }

## Problem 2: If complaining about the minimum SDK version,
solution: Change the minSDK version in android/app/build.gradle to 21

## Problem 3: Incompatibility with firebase_ml_vision
solution: Use google_mlkit_text_recognition package instead.
