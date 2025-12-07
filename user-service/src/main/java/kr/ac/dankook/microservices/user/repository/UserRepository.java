package kr.ac.dankook.microservices.user.repository;


import kr.ac.dankook.microservices.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;


import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {


    Optional<User> findByEmail(String email);

    Optional<User> findByAccountId(String accountId);

    Optional<User> findByEmailAndName(String email, String name);

    Optional<User> findByEmailAndNameAndAccountId(String email, String name, String accountId);

    boolean existsByAccountId(String accountId);
}
