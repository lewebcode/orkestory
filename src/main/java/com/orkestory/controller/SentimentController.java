package com.orkestory.controller;

import com.orkestory.service.SentimentService;
import com.orkestory.service.LoadTestService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class SentimentController {

    @Autowired
    private SentimentService sentimentService;

    @Autowired
    private LoadTestService loadTestService;

    @GetMapping("/sentiment")
    public ResponseEntity<Map<String, Object>> analyzeSentiment(@RequestParam String text) {
        if (text == null || text.trim().isEmpty()) {
            Map<String, Object> error = new HashMap<>();
            error.put("error", "Text parameter is required");
            return ResponseEntity.badRequest().body(error);
        }

        String sentiment = sentimentService.analyze(text);
        Map<String, Object> response = new HashMap<>();
        response.put("sentiment", sentiment);
        response.put("text", text);
        response.put("confidence", sentimentService.getConfidence(text));
        
        return ResponseEntity.ok(response);
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, String>> health() {
        Map<String, String> status = new HashMap<>();
        status.put("status", "UP");
        return ResponseEntity.ok(status);
    }

    @GetMapping("/load")
    public ResponseEntity<Map<String, Object>> generateLoad(
            @RequestParam(defaultValue = "1000") int duration,
            @RequestParam(defaultValue = "1000") int intensity,
            @RequestParam(defaultValue = "cpu") String type) {
        
        Map<String, Object> response = new HashMap<>();
        long startTime = System.currentTimeMillis();
        
        try {
            if ("cpu".equalsIgnoreCase(type)) {
                long iterations = loadTestService.generateCpuLoad(duration, intensity);
                long executionTime = System.currentTimeMillis() - startTime;
                
                response.put("type", "cpu");
                response.put("duration", duration);
                response.put("intensity", intensity);
                response.put("iterations", iterations);
                response.put("executionTimeMs", executionTime);
                response.put("status", "success");
            } else if ("memory".equalsIgnoreCase(type)) {
                long allocated = loadTestService.generateMemoryLoad(intensity);
                long executionTime = System.currentTimeMillis() - startTime;
                
                response.put("type", "memory");
                response.put("sizeMB", intensity);
                response.put("allocatedBytes", allocated);
                response.put("executionTimeMs", executionTime);
                response.put("status", "success");
            } else {
                response.put("error", "Invalid type. Use 'cpu' or 'memory'");
                return ResponseEntity.badRequest().body(response);
            }
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put("error", e.getMessage());
            response.put("status", "error");
            return ResponseEntity.internalServerError().body(response);
        }
    }
}
