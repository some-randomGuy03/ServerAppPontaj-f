# Fix Java PATH Issue

Your system has Java 25 installed, but your command prompt is still using Java 8. Here's how to fix it:

## Step 1: Find Java 25 Installation

Run these commands to find where Java 25 is installed:

```bash
dir "C:\Program Files\Eclipse Adoptium" /b
```

Or:

```bash
dir "C:\Program Files\Java" /b
```

Or check:
- `C:\Program Files\Eclipse Adoptium\jdk-25.x.x-hotspot`
- `C:\Program Files\Java\jdk-25.x.x`

## Step 2: Configure Gradle to Use Java 25

Once you find the path, edit `android/gradle.properties` and add this line (replace with your actual path):

```
org.gradle.java.home=C:\\Program Files\\Eclipse Adoptium\\jdk-25.0.1.9-hotspot
```

**Important:** Use double backslashes (`\\`) in the path!

## Step 3: Update System PATH (Optional but Recommended)

1. Press `Win + R`, type `sysdm.cpl`, press Enter
2. Go to "Advanced" tab → "Environment Variables"
3. Under "System variables", find "Path" and click "Edit"
4. Find the Java 8 entry (usually `C:\Program Files\Java\jdk1.8.0_xxx\bin`)
5. Either remove it or move Java 25's path above it
6. Add Java 25's path: `C:\Program Files\Eclipse Adoptium\jdk-25.0.1.9-hotspot\bin`
7. Click OK on all dialogs
8. **Close and reopen your command prompt**

## Step 4: Verify

After updating PATH, close and reopen command prompt, then:
```bash
java -version
```

Should show Java 25.

## Quick Fix: Just Configure Gradle

If you don't want to change PATH, just find Java 25's path and add it to `gradle.properties`:

```
org.gradle.java.home=C:\\Program Files\\Eclipse Adoptium\\jdk-25.0.1.9-hotspot
```

Then run:
```bash
flutter clean
flutter run
```





