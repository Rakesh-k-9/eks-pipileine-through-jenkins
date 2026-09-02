package com.example.devops.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HomeController {

    @GetMapping("/")
    public String home() {
        return """
                <html>
                    <head>
                        <title>DevOps CI/CD Project</title>
                    </head>
                    <body style="font-family: Arial; text-align: center; margin-top: 100px;">
                        <h1>DevOps CI/CD Pipeline</h1>
                        <h2>Successfully deployed on AWS EKS!</h2>
                        <p>GitHub → Jenkins → Docker → Amazon ECR → EKS → Ingress</p>
                        <p><b>Application:</b> Spring Boot</p>
                        <p><b>Version:</b> 1.0</p>
                    </body>
                </html>
                """;
    }

    @GetMapping("/health")
    public String health() {
        return "Application is UP and running!";
    }
}
