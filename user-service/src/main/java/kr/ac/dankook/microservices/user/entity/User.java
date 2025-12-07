package kr.ac.dankook.microservices.user.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

@Entity
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
public class User {

    @Id
    @GeneratedValue(strategy= GenerationType.IDENTITY) // MySQL 기준 Auto Increment
    private Long userId;
    private String email;
    private String accountId;
    private String password;
    private String phone_number;
    private String name;

    @CreatedDate
    private LocalDateTime created_at;

    @LastModifiedDate
    private LocalDateTime update_at;

    public User(String accountId, String email, String password, String name,String phone_number) {
        this.accountId = accountId;
        this.email = email;
        this.password = password;
        this.phone_number = phone_number;
        this.name = name;
    }


}
