package com.orkestory.service;

import org.springframework.stereotype.Service;
import java.util.Random;

@Service
public class LoadTestService {

    private final Random random = new Random();

    /**
     * Генерирует CPU нагрузку, выполняя вычисления
     * @param durationMs продолжительность нагрузки в миллисекундах
     * @param intensity интенсивность вычислений (количество итераций)
     * @return количество выполненных итераций
     */
    public long generateCpuLoad(int durationMs, int intensity) {
        long iterations = 0;
        long startTime = System.currentTimeMillis();
        long endTime = startTime + durationMs;

        while (System.currentTimeMillis() < endTime) {
            // CPU-интенсивные вычисления
            for (int i = 0; i < intensity; i++) {
                // Математические вычисления (результат не используется, только для нагрузки)
                @SuppressWarnings("unused")
                double result = Math.sqrt(Math.sin(random.nextDouble()) * 
                                        Math.cos(random.nextDouble()) * 
                                        Math.pow(random.nextDouble(), 2));
                iterations++;
            }
        }

        return iterations;
    }

    /**
     * Генерирует память нагрузку, выделяя и освобождая память
     * @param sizeMB размер в МБ
     * @return количество выделенных байт
     */
    public long generateMemoryLoad(int sizeMB) {
        try {
            byte[] array = new byte[sizeMB * 1024 * 1024];
            // Заполнение массива
            for (int i = 0; i < array.length; i += 1024) {
                array[i] = (byte) random.nextInt(256);
            }
            return array.length;
        } catch (OutOfMemoryError e) {
            return 0;
        }
    }
}
