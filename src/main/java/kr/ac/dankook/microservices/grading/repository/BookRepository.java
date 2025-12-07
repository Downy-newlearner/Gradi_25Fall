
package kr.ac.dankook.microservices.grading.repository;

import kr.ac.dankook.microservices.grading.entity.Book;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface BookRepository extends JpaRepository<Book, Long> {

    Optional<Book> findBookByBookId(Long bookId);
}
