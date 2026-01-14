package com.orkestory.service;

import org.springframework.stereotype.Service;
import java.util.Locale;
import java.util.regex.Pattern;

@Service
public class SentimentService {

    // Positive sentiment keywords
    private static final String[] POSITIVE_WORDS = {
        "good", "great", "excellent", "amazing", "wonderful", "fantastic", 
        "love", "happy", "joy", "pleased", "satisfied", "perfect", "brilliant",
        "outstanding", "superb", "delighted", "glad", "positive", "awesome",
        "best", "better", "nice", "fine", "ok", "okay", "yes", "yeah", "yay",
        "smile", "smiling", "success", "win", "beautiful", "gorgeous", "stunning",
        "impressive", "marvelous", "terrific", "fabulous", "super", "cool", "sweet",
        "lovely", "charming", "pleasant", "enjoyable", "delightful", "grateful",
        "thankful", "blessed", "lucky", "fortunate", "proud", "excited", "thrilled"
    };

    // Negative sentiment keywords
    private static final String[] NEGATIVE_WORDS = {
        "bad", "terrible", "awful", "horrible", "hate", "sad", "angry", "mad",
        "furious", "disappointed", "frustrated", "annoyed", "irritated", "upset",
        "worried", "anxious", "stressed", "depressed", "miserable", "unhappy",
        "unpleasant", "disgusting", "revolting", "repulsive", "offensive", "vile",
        "nasty", "mean", "cruel", "harsh", "brutal", "violent", "aggressive",
        "hostile", "threatening", "dangerous", "risky", "failed", "lost", "broken",
        "damaged", "destroyed", "ruined", "spoiled", "corrupt", "fake", "false"
    };

    private static final Pattern POSITIVE_PATTERN = Pattern.compile(
        "\\b(" + String.join("|", POSITIVE_WORDS) + ")\\b",
        Pattern.CASE_INSENSITIVE
    );

    private static final Pattern NEGATIVE_PATTERN = Pattern.compile(
        "\\b(" + String.join("|", NEGATIVE_WORDS) + ")\\b",
        Pattern.CASE_INSENSITIVE
    );

    public String analyze(String text) {
        if (text == null || text.trim().isEmpty()) {
            return "neutral";
        }

        String lowerText = text.toLowerCase(Locale.ENGLISH);
        
        int positiveCount = countMatches(POSITIVE_PATTERN, lowerText);
        int negativeCount = countMatches(NEGATIVE_PATTERN, lowerText);

        if (positiveCount > negativeCount) {
            return "positive";
        } else if (negativeCount > positiveCount) {
            return "negative";
        } else {
            return "neutral";
        }
    }

    public double getConfidence(String text) {
        if (text == null || text.trim().isEmpty()) {
            return 0.0;
        }

        String lowerText = text.toLowerCase(Locale.ENGLISH);
        int positiveCount = countMatches(POSITIVE_PATTERN, lowerText);
        int negativeCount = countMatches(NEGATIVE_PATTERN, lowerText);
        int totalMatches = positiveCount + negativeCount;

        if (totalMatches == 0) {
            return 0.5; // Neutral confidence
        }

        double confidence = Math.abs(positiveCount - negativeCount) / (double) totalMatches;
        return Math.min(0.95, Math.max(0.5, confidence));
    }

    private int countMatches(Pattern pattern, String text) {
        return (int) pattern.matcher(text).results().count();
    }
}
