package kr.ac.dankook.microservices.user.service;


import kr.ac.dankook.microservices.common.dto.CustomUserDetails;
import kr.ac.dankook.microservices.user.entity.User;
import kr.ac.dankook.microservices.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Slf4j
public class CustomUserDetailsService implements UserDetailsService {

    private final UserRepository userRepository;

    @Override
    @Transactional
    public UserDetails loadUserByUsername(String accountId) throws UsernameNotFoundException {
        return userRepository.findByAccountId(accountId)
                .map(this::createUserDetails)
                .orElseThrow(() -> new UsernameNotFoundException("해당 아이디를 가진 사용자를 찾을 수 없습니다."));
    }

    private UserDetails createUserDetails(User user) {
        return CustomUserDetails.builder()
                .accountId(user.getAccountId())
                .userId(user.getUserId())
                .name(user.getName())
                .password(user.getPassword())
                .build();
    }
}
